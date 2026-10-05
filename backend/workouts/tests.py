from datetime import timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from .models import Challenge, Workout


class WorkoutApiTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username="athlete@example.com",
            email="athlete@example.com",
            password="StrongPass123!",
        )
        self.token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.token.key}")

    def test_registration_and_login_issue_a_token(self):
        registration = self.client.post(
            "/api/auth/register",
            {"email": "new@example.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(registration.status_code, 201)
        self.assertTrue(registration.data["token"])

        self.client.credentials()
        login = self.client.post(
            "/api/auth/login",
            {"email": "new@example.com", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(login.status_code, 200)
        self.assertTrue(login.data["token"])

    def test_plan_has_28_days_and_a_completed_workout_updates_tracker(self):
        response = self.client.get("/api/plan?focus=legs&difficulty=beginner")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data["days"]), 28)
        self.assertTrue(response.data["days"][0]["exercises"])
        self.assertTrue(response.data["days"][6]["isRestDay"])
        for day in response.data["days"]:
            for exercise in day["exercises"]:
                with self.subTest(day=day["dayNumber"], exercise=exercise["id"]):
                    self.assertIsInstance(exercise["durationSeconds"], int)
                    self.assertIsInstance(exercise["sets"], int)
                    self.assertIsInstance(exercise["repetitions"], int)

        challenge = Challenge.objects.get(user=self.user, focus="legs")
        challenge.start_date = timezone.localdate() - timedelta(days=1)
        challenge.save(update_fields=["start_date"])
        finish = self.client.post(
            "/api/workouts",
            {
                "focus": "legs",
                "difficulty": "beginner",
                "dayNumber": 1,
                "durationMinutes": 14,
            },
            format="json",
        )
        self.assertEqual(finish.status_code, 201)
        self.assertEqual(finish.data["caloriesBurned"], 70)
        self.assertEqual(finish.data["exerciseCount"], 4)

        repeated = self.client.post(
            "/api/workouts",
            {
                "focus": "legs",
                "difficulty": "beginner",
                "dayNumber": 1,
                "durationMinutes": 14,
            },
            format="json",
        )
        self.assertEqual(repeated.status_code, 409)
        self.assertEqual(
            self.client.get("/api/stats").data,
            {
                "completedDays": 1,
                "totalExercises": 4,
                "totalCalories": 70,
                "totalMinutes": 14,
            },
        )

    def test_workouts_are_private_to_the_authenticated_user(self):
        challenge = Challenge.objects.create(
            user=self.user,
            focus="abs",
            difficulty="beginner",
            start_date=timezone.localdate(),
        )
        Workout.objects.create(
            challenge=challenge,
            day_number=1,
            title="Abs · วันที่ 1",
            duration_minutes=10,
            exercise_count=4,
            calories_burned=50,
        )
        self.client.credentials()
        anonymous_response = self.client.get("/api/workouts")
        self.assertEqual(anonymous_response.status_code, 401)

        another_user = get_user_model().objects.create_user(
            username="other@example.com",
            email="other@example.com",
            password="StrongPass123!",
        )
        other_token = Token.objects.create(user=another_user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {other_token.key}")
        self.assertEqual(self.client.get("/api/workouts").data, [])

    def test_profile_can_be_read_and_updated_for_authenticated_user(self):
        response = self.client.get("/api/profile")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, {
            "email": "athlete@example.com",
            "gender": None,
            "age": None,
            "weightKg": None,
            "heightCm": None,
        })

        updated = self.client.patch(
            "/api/profile",
            {
                "gender": "female",
                "age": 28,
                "weightKg": "62.5",
                "heightCm": "168.0",
            },
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.data["gender"], "female")
        self.assertEqual(updated.data["age"], 28)
        self.assertEqual(str(updated.data["weightKg"]), "62.5")
        self.assertEqual(str(updated.data["heightCm"]), "168.0")

        self.client.credentials()
        self.assertEqual(self.client.get("/api/profile").status_code, 401)

    def test_profile_rejects_invalid_personal_data(self):
        response = self.client.patch(
            "/api/profile",
            {
                "gender": "invalid",
                "age": 121,
                "weightKg": "0",
                "heightCm": "301",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_three_consecutive_completed_workouts_create_a_recovery_day(self):
        challenge = Challenge.objects.create(
            user=self.user,
            focus="abs",
            difficulty="beginner",
            start_date=timezone.localdate() - timedelta(days=3),
        )
        for day_number in (1, 2, 3):
            Workout.objects.create(
                challenge=challenge,
                day_number=day_number,
                title=f"Abs · วันที่ {day_number}",
                duration_minutes=10,
                exercise_count=4,
                calories_burned=50,
            )

        plan = self.client.get("/api/plan?focus=abs&difficulty=beginner")
        self.assertEqual(plan.status_code, 200)
        recovery_day = plan.data["days"][3]
        self.assertTrue(recovery_day["isRestDay"])
        self.assertEqual(recovery_day["title"], "วันพักฟื้นหลังฝึกต่อเนื่อง")
        self.assertEqual(
            recovery_day["exercises"][0]["id"],
            "recovery-stretch",
        )
        self.assertTrue(recovery_day["isAvailable"])
        self.assertFalse(plan.data["days"][4]["isRestDay"])

        response = self.client.post(
            "/api/workouts",
            {
                "focus": "abs",
                "difficulty": "beginner",
                "dayNumber": 4,
                "durationMinutes": 5,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.data["detail"], "วันนี้เป็นวันพัก ไม่ต้องบันทึกการฝึก")

    def test_missing_training_day_breaks_the_consecutive_streak(self):
        challenge = Challenge.objects.create(
            user=self.user,
            focus="abs",
            difficulty="beginner",
            start_date=timezone.localdate() - timedelta(days=3),
        )
        for day_number in (1, 3):
            Workout.objects.create(
                challenge=challenge,
                day_number=day_number,
                title=f"Abs · วันที่ {day_number}",
                duration_minutes=10,
                exercise_count=4,
                calories_burned=50,
            )

        plan = self.client.get("/api/plan?focus=abs&difficulty=beginner")
        self.assertFalse(plan.data["days"][3]["isRestDay"])
