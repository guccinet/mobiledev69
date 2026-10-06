from datetime import timedelta
from django.conf import settings
from django.db.models import Sum
from django.contrib import messages
from django.contrib.auth import login
from django.db import IntegrityError, transaction
from django.http import FileResponse, HttpResponseNotFound
from django.shortcuts import get_object_or_404
from django.shortcuts import redirect, render
from django.urls import reverse
from django.utils import timezone
from django.utils.http import url_has_allowed_host_and_scheme
from rest_framework import status
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
from .calorie_estimation import estimate_calories_burned
from .forms import RegistrationForm
from .models import UserProfile, WeightEntry, Workout
from .serializers import (
    CompleteWorkoutSerializer,
    UserProfileSerializer,
    WeightEntrySerializer,
    WorkoutUpdateSerializer,
)


def register(request):
    next_url = request.POST.get("next") or request.GET.get("next", "")
    form = RegistrationForm(
        request.POST if request.method == "POST" else None
    )

    if request.method == "POST" and form.is_valid():
        try:
            with transaction.atomic():
                user = form.save()
        except IntegrityError:
            form.add_error("email", "อีเมลนี้ถูกใช้สมัครบัญชีแล้ว")
        else:
            login(
                request,
                user,
                backend="django.contrib.auth.backends.ModelBackend",
            )
            messages.success(request, "สร้างบัญชีสำเร็จ กำลังเข้าสู่ระบบ")
            if url_has_allowed_host_and_scheme(
                next_url,
                allowed_hosts={request.get_host()},
                require_https=request.is_secure(),
            ):
                return redirect(next_url)
            return redirect(reverse("login"))

    return render(
        request,
        "registration/register.html",
        {"form": form, "next": next_url},
    )


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


@transaction.atomic
def record_weight(user, weight_kg):
    profile, _ = UserProfile.objects.get_or_create(user=user)
    profile.weight_kg = weight_kg
    profile.save(update_fields=["weight_kg"])
    return WeightEntry.objects.create(user=user, weight_kg=weight_kg)


def frontend_app(_request):
    index_file = settings.FRONTEND_BUILD_DIR / "index.html"
    if not index_file.is_file():
        return HttpResponseNotFound("Flutter web build is unavailable.")
    return FileResponse(index_file.open("rb"), content_type="text/html")


class HealthView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, _request):
        return Response({"status": "ok"})


class ProfileView(APIView):
    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        return Response(UserProfileSerializer(profile).data)

    def patch(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        previous_weight = profile.weight_kg
        serializer = UserProfileSerializer(
            profile,
            data=request.data,
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        with transaction.atomic():
            serializer.save()
            if (
                profile.weight_kg is not None
                and profile.weight_kg != previous_weight
            ):
                WeightEntry.objects.create(
                    user=request.user,
                    weight_kg=profile.weight_kg,
                )
        return Response(serializer.data)


class WeightHistoryView(APIView):
    def get(self, request):
        entries = WeightEntry.objects.filter(user=request.user)
        return Response(WeightEntrySerializer(entries, many=True).data)

    def post(self, request):
        serializer = WeightEntrySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        entry = record_weight(
            request.user,
            serializer.validated_data["weight_kg"],
        )
        return Response(
            WeightEntrySerializer(entry).data,
            status=status.HTTP_201_CREATED,
        )


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
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        workout = Workout.objects.create(
            challenge=challenge,
            day_number=day_number,
            title=day["title"],
            duration_minutes=duration_minutes,
            exercise_count=exercise_count,
            calories_burned=estimate_calories_burned(
                profile.weight_kg,
                duration_minutes,
                challenge.difficulty,
            ),
        )
        return Response(workout_json(workout), status=status.HTTP_201_CREATED)


class WorkoutDetailView(APIView):
    def get_workout(self, request, workout_id):
        return get_object_or_404(
            Workout.objects.select_related("challenge"),
            pk=workout_id,
            challenge__user=request.user,
        )

    def get(self, request, workout_id):
        return Response(workout_json(self.get_workout(request, workout_id)))

    def put(self, request, workout_id):
        return self.update(request, workout_id, partial=False)

    def patch(self, request, workout_id):
        return self.update(request, workout_id, partial=True)

    def update(self, request, workout_id, partial):
        workout = self.get_workout(request, workout_id)
        serializer = WorkoutUpdateSerializer(
            workout,
            data=request.data,
            partial=partial,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(workout_json(workout))

    def delete(self, request, workout_id):
        self.get_workout(request, workout_id).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class StatsView(APIView):
    def get(self, request):
        workouts = Workout.objects.filter(challenge__user=request.user)
        totals = workouts.aggregate(
            exercise_count=Sum("exercise_count"),
            calories_burned=Sum("calories_burned"),
            duration_minutes=Sum("duration_minutes"),
        )
        has_calculated_calories = workouts.filter(
            calories_burned__isnull=False
        ).exists()
        total_calories = (
            (totals["calories_burned"] or 0)
            if has_calculated_calories
            else None
        )
        return Response(
            {
                "completedDays": workouts.values("completed_at__date").distinct().count(),
                "totalExercises": totals["exercise_count"] or 0,
                "totalCalories": total_calories,
                "totalMinutes": totals["duration_minutes"] or 0,
            }
        )
