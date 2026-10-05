from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db.models import Sum
from django.utils import timezone
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .catalog import (
    DIFFICULTY_LABELS,
    FOCUS_LABELS,
    exercise_catalog,
    get_or_create_challenge,
    make_plan,
)
from .models import UserProfile, Workout
from .serializers import (
    CompleteWorkoutSerializer,
    LoginSerializer,
    RegistrationSerializer,
    UserProfileSerializer,
)


User = get_user_model()


def workout_json(workout):
    return {
        "id": workout.pk,
        "title": workout.title,
        "focus": workout.challenge.focus,
        "difficulty": workout.challenge.difficulty,
        "dayNumber": workout.day_number,
        "durationMinutes": workout.duration_minutes,
        "exerciseCount": workout.exercise_count,
        "caloriesBurned": workout.calories_burned,
        "completedAt": workout.completed_at.isoformat(),
    }


class HealthView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, _request):
        return Response({"status": "ok"})


class RegisterView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = RegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        token, _ = Token.objects.get_or_create(user=user)
        return Response(
            {"token": token.key, "email": user.email},
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = LoginSerializer(
            data=request.data,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        token, _ = Token.objects.get_or_create(user=user)
        return Response({"token": token.key, "email": user.email})


class LogoutView(APIView):
    def post(self, request):
        request.auth.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ProfileView(APIView):
    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        return Response(UserProfileSerializer(profile).data)

    def patch(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = UserProfileSerializer(
            profile,
            data=request.data,
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class ExerciseListView(APIView):
    def get(self, request):
        focus = request.query_params.get("focus", "abs")
        difficulty = request.query_params.get("difficulty", "beginner")
        if focus not in FOCUS_LABELS or difficulty not in DIFFICULTY_LABELS:
            return Response(
                {"detail": "เลือกพื้นที่ฝึกหรือระดับความยากไม่ถูกต้อง"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(exercise_catalog(focus, difficulty))


class PlanView(APIView):
    def get(self, request):
        focus = request.query_params.get("focus", "abs")
        difficulty = request.query_params.get("difficulty", "beginner")
        if focus not in FOCUS_LABELS or difficulty not in DIFFICULTY_LABELS:
            return Response(
                {"detail": "เลือกพื้นที่ฝึกหรือระดับความยากไม่ถูกต้อง"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        challenge = get_or_create_challenge(request.user, focus, difficulty)
        return Response(make_plan(challenge))


class WorkoutListView(APIView):
    def get(self, request):
        workouts = Workout.objects.filter(challenge__user=request.user).select_related(
            "challenge"
        )
        return Response([workout_json(workout) for workout in workouts])

    def post(self, request):
        serializer = CompleteWorkoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        challenge = get_or_create_challenge(
            request.user,
            data["focus"],
            data["difficulty"],
        )
        day_number = data["dayNumber"]
        challenge_day = challenge.start_date + timedelta(days=day_number - 1)
        if challenge_day > timezone.localdate():
            return Response(
                {"detail": "ยังไม่ถึงวันฝึกนี้ในตาราง"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if Workout.objects.filter(challenge=challenge, day_number=day_number).exists():
            return Response(
                {"detail": "บันทึกวันนี้ไปแล้ว"},
                status=status.HTTP_409_CONFLICT,
            )

        plan = make_plan(challenge)
        day = plan["days"][day_number - 1]
        if day["isRestDay"]:
            return Response(
                {"detail": "วันนี้เป็นวันพัก ไม่ต้องบันทึกการฝึก"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        exercise_count = len(day["exercises"])
        duration_minutes = data["durationMinutes"]
        workout = Workout.objects.create(
            challenge=challenge,
            day_number=day_number,
            title=day["title"],
            duration_minutes=duration_minutes,
            exercise_count=exercise_count,
            calories_burned=max(1, round(duration_minutes * 5)),
        )
        return Response(workout_json(workout), status=status.HTTP_201_CREATED)


class StatsView(APIView):
    def get(self, request):
        workouts = Workout.objects.filter(challenge__user=request.user)
        totals = workouts.aggregate(
            exercise_count=Sum("exercise_count"),
            calories_burned=Sum("calories_burned"),
            duration_minutes=Sum("duration_minutes"),
        )
        return Response(
            {
                "completedDays": workouts.values("completed_at__date").distinct().count(),
                "totalExercises": totals["exercise_count"] or 0,
                "totalCalories": totals["calories_burned"] or 0,
                "totalMinutes": totals["duration_minutes"] or 0,
            }
        )
