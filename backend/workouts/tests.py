from datetime import timedelta
from hashlib import sha256
from base64 import urlsafe_b64encode
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.test import TestCase
from django.utils import timezone
from oidc_provider.models import Client, Code, RSAKey, ResponseType, Token
from oidc_provider.lib.utils.common import get_issuer
from rest_framework.test import APITestCase

from .calorie_estimation import estimate_calories_burned
from .models import Challenge, UserProfile, WeightEntry, Workout


class RegistrationTests(TestCase):
    def test_registration_creates_user_and_continues_oidc_authorization(self):
        next_url = "/oidc/authorize?client_id=movedaily-flutter"
        response = self.client.post(
            "/accounts/register/",
            {
                "email": " NewAthlete@Example.com ",
                "password1": "WorkoutSecure!2026",
                "password2": "WorkoutSecure!2026",
                "next": next_url,
            },
        )

        self.assertRedirects(response, next_url, fetch_redirect_response=False)
        user = get_user_model().objects.get(username="newathlete@example.com")
        self.assertEqual(user.email, "newathlete@example.com")
        self.assertTrue(user.check_password("WorkoutSecure!2026"))
        profile = UserProfile.objects.get(user=user)
        self.assertIsNone(profile.gender)
        self.assertIsNone(profile.age)
        self.assertIsNone(profile.weight_kg)
        self.assertIsNone(profile.height_cm)
        self.assertEqual(
            self.client.session["_auth_user_id"],
            str(user.pk),
        )

    def test_registration_saves_optional_personal_profile_data(self):
        response = self.client.post(
            "/accounts/register/",
            {
                "email": "profile@example.com",
                "gender": "female",
                "age": "28",
                "weight_kg": "62.5",
                "height_cm": "168.0",
                "password1": "WorkoutSecure!2026",
                "password2": "WorkoutSecure!2026",
            },
        )

        self.assertRedirects(
            response,
            "/accounts/login/",
            fetch_redirect_response=False,
        )
        user = get_user_model().objects.get(username="profile@example.com")
        profile = UserProfile.objects.get(user=user)
        self.assertEqual(profile.gender, "female")
        self.assertEqual(profile.age, 28)
        self.assertEqual(str(profile.weight_kg), "62.5")
        self.assertEqual(str(profile.height_cm), "168.0")
        self.assertEqual(
            list(WeightEntry.objects.filter(user=user).values_list("weight_kg", flat=True)),
            [profile.weight_kg],
        )

    def test_registration_rejects_out_of_range_profile_data(self):
        response = self.client.post(
            "/accounts/register/",
            {
                "email": "invalid-profile@example.com",
                "age": "121",
                "weight_kg": "0",
                "height_cm": "301",
                "password1": "WorkoutSecure!2026",
                "password2": "WorkoutSecure!2026",
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn("age", response.context["form"].errors)
        self.assertIn("weight_kg", response.context["form"].errors)
        self.assertIn("height_cm", response.context["form"].errors)
        self.assertFalse(
            get_user_model().objects.filter(
                username="invalid-profile@example.com"
            ).exists()
        )

    def test_registration_rejects_duplicate_email_and_mismatched_passwords(self):
        get_user_model().objects.create_user(
            username="existing@example.com",
            email="existing@example.com",
            password="ExistingSecure!2026",
        )
        response = self.client.post(
            "/accounts/register/",
            {
                "email": "EXISTING@example.com",
                "password1": "WorkoutSecure!2026",
                "password2": "NotTheSameSecure!2026",
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "อีเมลนี้ถูกใช้สมัครบัญชีแล้ว")
        self.assertContains(response, "รหัสผ่านทั้งสองช่องไม่ตรงกัน")
        self.assertEqual(get_user_model().objects.count(), 1)

    def test_registration_does_not_redirect_to_an_external_next_url(self):
        response = self.client.post(
            "/accounts/register/",
            {
                "email": "newathlete@example.com",
                "password1": "WorkoutSecure!2026",
                "password2": "WorkoutSecure!2026",
                "next": "//attacker.example/collect",
            },
        )

        self.assertRedirects(
            response,
            "/accounts/login/",
            fetch_redirect_response=False,
        )

    def test_login_page_offers_registration_and_preserves_oidc_return_url(self):
        next_url = "/oidc/authorize?client_id=movedaily-flutter"
        response = self.client.get(f"/accounts/login/?next={next_url}")

        self.assertEqual(response.status_code, 200)
        self.assertContains(
            response,
            "/accounts/register/?next=/oidc/authorize"
            "%3Fclient_id%3Dmovedaily-flutter",
        )

    def test_registration_page_shows_optional_profile_fields(self):
        response = self.client.get("/accounts/register/")

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'name="gender"')
        self.assertContains(response, 'name="age"')
        self.assertContains(response, 'name="weight_kg"')
        self.assertContains(response, 'name="height_cm"')
        self.assertContains(response, "กรอกหรือเว้นว่างก็ได้")


class WorkoutApiTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username="athlete@example.com",
            email="athlete@example.com",
            password="athlete-test-password",
        )
        self.oidc_client = Client.objects.create(
            name="MoveDaily test client",
            owner=self.user,
            client_type="public",
            client_id="movedaily-flutter",
            jwt_alg="RS256",
        )
        self.oidc_client.redirect_uris = ["http://localhost:50000/redirect.html"]
        self.oidc_client.scope = ["openid", "profile", "email"]
        self.oidc_client.save()
        self.oidc_client.response_types.add(ResponseType.objects.get(value="code"))
        self.token = self.make_token(self.user, "test-access-token")
        self.authenticate_as(self.token)

    def make_token(self, user, access_token, client=None, claims=None):
        token = Token(
            client=client or self.oidc_client,
            user=user,
            access_token=access_token,
            refresh_token=f"refresh-{access_token}",
            expires_at=timezone.now() + timedelta(minutes=5),
        )
        token.scope = ["openid", "profile", "email"]
        token.id_token = claims or {
            "iss": get_issuer(),
            "aud": self.oidc_client.client_id,
            "exp": int((timezone.now() + timedelta(minutes=5)).timestamp()),
            "iat": int(timezone.now().timestamp()),
        }
        token.save()
        return token

    def authenticate_as(self, token):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token.access_token}")

    def make_workout(self, user, day_number=1):
        challenge = Challenge.objects.create(
            user=user,
            focus="abs",
            difficulty="beginner",
            start_date=timezone.localdate(),
        )
        return Workout.objects.create(
            challenge=challenge,
            day_number=day_number,
            title=f"Abs · วันที่ {day_number}",
            duration_minutes=10,
            exercise_count=4,
            calories_burned=50,
        )

    def test_oidc_bearer_authentication_rejects_invalid_claims_and_tokens(self):
        self.client.credentials()
        self.assertEqual(self.client.get("/api/profile").status_code, 401)
        self.client.credentials(HTTP_AUTHORIZATION="Bearer unknown-token")
        self.assertEqual(self.client.get("/api/profile").status_code, 401)

        bad_claims = [
            {"iss": "https://attacker.example/oidc", "aud": "movedaily-flutter",
             "exp": int((timezone.now() + timedelta(minutes=5)).timestamp())},
            {"iss": get_issuer(), "aud": "other-client",
             "exp": int((timezone.now() + timedelta(minutes=5)).timestamp())},
            {"iss": get_issuer(), "aud": "movedaily-flutter",
             "exp": int((timezone.now() - timedelta(minutes=5)).timestamp())},
        ]
        for index, claims in enumerate(bad_claims):
            with self.subTest(index=index):
                token = self.make_token(self.user, f"invalid-claims-{index}", claims=claims)
                self.authenticate_as(token)
                self.assertEqual(self.client.get("/api/profile").status_code, 401)

        expired_token = self.make_token(self.user, "expired-record-token")
        expired_token.expires_at = timezone.now() - timedelta(seconds=1)
        expired_token.save(update_fields=["expires_at"])
        self.authenticate_as(expired_token)
        self.assertEqual(self.client.get("/api/profile").status_code, 401)

    def test_public_authorization_code_requires_pkce_s256(self):
        request_args = {
            "client_id": self.oidc_client.client_id,
            "redirect_uri": "http://localhost:50000/redirect.html",
            "response_type": "code",
            "scope": "openid profile email",
            "state": "test-state",
        }
        missing_pkce = self.client.get("/oidc/authorize", request_args)
        self.assertEqual(missing_pkce.status_code, 400)

        unsupported_method = self.client.get(
            "/oidc/authorize",
            {
                **request_args,
                "code_challenge": "a" * 43,
                "code_challenge_method": "plain",
            },
        )
        self.assertEqual(unsupported_method.status_code, 400)

        valid_pkce = self.client.get(
            "/oidc/authorize",
            {
                **request_args,
                "code_challenge": "a" * 43,
                "code_challenge_method": "S256",
            },
        )
        self.assertEqual(valid_pkce.status_code, 302)

    def test_oidc_discovery_and_login_template_are_available(self):
        discovery = self.client.get("/oidc/.well-known/openid-configuration")
        self.assertEqual(discovery.status_code, 200)
        self.assertEqual(discovery.json()["issuer"], get_issuer())

        login_page = self.client.get("/accounts/login/")
        self.assertEqual(login_page.status_code, 200)
        self.assertContains(login_page, "เข้าสู่ระบบ Move Daily")
        self.assertContains(login_page, 'name="username"')
        self.assertContains(login_page, "สมัครสมาชิก")
        self.assertContains(login_page, "/accounts/register/")

    def test_setup_demo_is_idempotent_and_creates_a_public_pkce_client(self):
        env = {"DEMO_USER_PASSWORD": "test-demo-password"}
        with patch.dict("os.environ", env):
            call_command(
                "setup_demo",
                email="demo@example.com",
                client_id="movedaily-demo-test",
                redirect_uri="http://localhost:50000/redirect.html",
                verbosity=0,
            )
            call_command(
                "setup_demo",
                email="demo@example.com",
                client_id="movedaily-demo-test",
                redirect_uri="http://localhost:50000/redirect.html",
                verbosity=0,
            )
        demo_user = get_user_model().objects.get(username="demo@example.com")
        demo_client = Client.objects.get(client_id="movedaily-demo-test")
        self.assertTrue(demo_user.check_password(env["DEMO_USER_PASSWORD"]))
        self.assertEqual(demo_client.client_type, "public")
        self.assertEqual(list(demo_client.response_type_values()), ["code"])
        self.assertEqual(demo_client.redirect_uris, ["http://localhost:50000/redirect.html"])
        self.assertEqual(Client.objects.filter(client_id="movedaily-demo-test").count(), 1)
        self.assertEqual(RSAKey.objects.count(), 1)

    def test_provider_token_endpoint_uses_code_verifier_for_pkce(self):
        with patch.dict("os.environ", {"DEMO_USER_PASSWORD": "test-demo-password"}):
            call_command(
                "setup_demo",
                email="demo@example.com",
                client_id=self.oidc_client.client_id,
                redirect_uri="http://localhost:50000/redirect.html",
                verbosity=0,
            )
        verifier = "a" * 43
        challenge = (
            urlsafe_b64encode(sha256(verifier.encode("ascii")).digest())
            .decode("ascii")
            .rstrip("=")
        )
        code = Code(
            client=self.oidc_client,
            user=self.user,
            code="test-pkce-code",
            expires_at=timezone.now() + timedelta(minutes=5),
            nonce="test-nonce",
            is_authentication=True,
            code_challenge=challenge,
            code_challenge_method="S256",
        )
        code.scope = ["openid", "profile", "email"]
        code.save()
        response = self.client.post(
            "/oidc/token",
            {
                "client_id": self.oidc_client.client_id,
                "grant_type": "authorization_code",
                "code": code.code,
                "redirect_uri": "http://localhost:50000/redirect.html",
                "code_verifier": "wrong-verifier",
            },
        )
        self.assertEqual(response.status_code, 400)
        self.assertTrue(Code.objects.filter(pk=code.pk).exists())

        response = self.client.post(
            "/oidc/token",
            {
                "client_id": self.oidc_client.client_id,
                "grant_type": "authorization_code",
                "code": code.code,
                "redirect_uri": "http://localhost:50000/redirect.html",
                "code_verifier": verifier,
            },
        )
        self.assertEqual(response.status_code, 200, response.content)
        access_token = response.json()["access_token"]
        self.assertTrue(access_token)
        self.assertFalse(Code.objects.filter(pk=code.pk).exists())
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access_token}")
        self.assertEqual(self.client.get("/api/profile").status_code, 200)

    def test_plan_has_28_days_and_a_completed_workout_updates_tracker(self):
        profile, _ = UserProfile.objects.get_or_create(user=self.user)
        profile.weight_kg = 70
        profile.save(update_fields=["weight_kg"])
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
        expected_calories = round(3.5 * 3.5 * 70 / 200 * 14)
        self.assertEqual(finish.data["caloriesBurned"], expected_calories)
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
                "totalCalories": expected_calories,
                "totalMinutes": 14,
            },
        )

    def test_workout_detail_supports_owner_scoped_crud(self):
        profile, _ = UserProfile.objects.get_or_create(user=self.user)
        profile.weight_kg = 70
        profile.save(update_fields=["weight_kg"])
        workout = self.make_workout(self.user)
        detail_url = f"/api/workouts/{workout.pk}"

        detail = self.client.get(detail_url)
        self.assertEqual(detail.status_code, 200)
        self.assertEqual(detail.data["id"], workout.pk)

        patched = self.client.patch(
            detail_url,
            {"title": "Updated workout", "durationMinutes": 12},
            format="json",
        )
        self.assertEqual(patched.status_code, 200)
        self.assertEqual(patched.data["title"], "Updated workout")
        self.assertEqual(
            patched.data["caloriesBurned"],
            round(3.5 * 3.5 * 70 / 200 * 12),
        )

        replaced = self.client.put(
            detail_url,
            {"title": "Replacement workout", "durationMinutes": 15},
            format="json",
        )
        self.assertEqual(replaced.status_code, 200)
        self.assertEqual(replaced.data["durationMinutes"], 15)
        self.assertEqual(
            replaced.data["caloriesBurned"],
            round(3.5 * 3.5 * 70 / 200 * 15),
        )
        self.assertEqual(self.client.delete(detail_url).status_code, 204)
        self.assertEqual(self.client.get(detail_url).status_code, 404)

    def test_workout_crud_hides_other_users_records(self):
        other_user = get_user_model().objects.create_user(
            username="other-athlete@example.com",
            email="other-athlete@example.com",
            password="other-test-password",
        )
        workout = self.make_workout(other_user)
        detail_url = f"/api/workouts/{workout.pk}"

        self.assertEqual(self.client.get(detail_url).status_code, 404)
        self.assertEqual(
            self.client.patch(
                detail_url,
                {"title": "Not allowed"},
                format="json",
            ).status_code,
            404,
        )
        self.assertEqual(
            self.client.delete(detail_url).status_code,
            404,
        )
        workout.refresh_from_db()
        self.assertTrue(Workout.objects.filter(pk=workout.pk).exists())
        self.assertEqual(workout.title, "Abs · วันที่ 1")

    def test_workouts_are_private_to_the_authenticated_user(self):
        workout = self.make_workout(self.user)
        self.client.credentials()
        anonymous_response = self.client.get("/api/workouts")
        self.assertEqual(anonymous_response.status_code, 401)

        another_user = get_user_model().objects.create_user(
            username="other@example.com",
            email="other@example.com",
            password="other-test-password",
        )
        other_token = self.make_token(another_user, "other-user-token")
        self.authenticate_as(other_token)
        self.assertEqual(self.client.get("/api/workouts").data, [])
        self.assertEqual(self.client.get(f"/api/workouts/{workout.pk}").status_code, 404)

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

    def test_weight_history_records_readings_and_updates_profile_weight(self):
        initial = self.client.get("/api/weights")
        self.assertEqual(initial.status_code, 200)
        self.assertEqual(initial.data, [])

        first = self.client.post(
            "/api/weights",
            {"weightKg": "70.5"},
            format="json",
        )
        self.assertEqual(first.status_code, 201)
        self.assertEqual(str(first.data["weightKg"]), "70.5")

        second = self.client.post(
            "/api/weights",
            {"weightKg": "69.8"},
            format="json",
        )
        self.assertEqual(second.status_code, 201)
        self.assertEqual(str(second.data["weightKg"]), "69.8")

        history = self.client.get("/api/weights")
        self.assertEqual(history.status_code, 200)
        self.assertEqual(len(history.data), 2)
        self.assertEqual(
            [item["weightKg"] for item in history.data],
            ["70.5", "69.8"],
        )
        profile = self.client.get("/api/profile")
        self.assertEqual(str(profile.data["weightKg"]), "69.8")

    def test_weight_history_rejects_invalid_weight_and_is_private(self):
        invalid = self.client.post(
            "/api/weights",
            {"weightKg": "0"},
            format="json",
        )
        self.assertEqual(invalid.status_code, 400)
        self.assertEqual(WeightEntry.objects.count(), 0)

        self.client.credentials()
        self.assertEqual(self.client.get("/api/weights").status_code, 401)
        self.assertEqual(
            self.client.post(
                "/api/weights",
                {"weightKg": "60"},
                format="json",
            ).status_code,
            401,
        )

    def test_profile_weight_changes_are_added_to_weight_history(self):
        profile_url = "/api/profile"
        first = self.client.patch(
            profile_url,
            {"weightKg": "71.2"},
            format="json",
        )
        self.assertEqual(first.status_code, 200)
        self.assertEqual(WeightEntry.objects.filter(user=self.user).count(), 1)

        unchanged = self.client.patch(
            profile_url,
            {"weightKg": "71.2"},
            format="json",
        )
        self.assertEqual(unchanged.status_code, 200)
        self.assertEqual(WeightEntry.objects.filter(user=self.user).count(), 1)

        changed = self.client.patch(
            profile_url,
            {"weightKg": "70.4"},
            format="json",
        )
        self.assertEqual(changed.status_code, 200)
        self.assertEqual(WeightEntry.objects.filter(user=self.user).count(), 2)

    def test_calorie_estimate_uses_met_weight_and_training_difficulty(self):
        profile, _ = UserProfile.objects.get_or_create(user=self.user)
        profile.weight_kg = 70
        profile.save(update_fields=["weight_kg"])
        challenge = Challenge.objects.create(
            user=self.user,
            focus="legs",
            difficulty="beginner",
            start_date=timezone.localdate() - timedelta(days=1),
        )

        response = self.client.post(
            "/api/workouts",
            {
                "focus": "legs",
                "difficulty": "beginner",
                "dayNumber": 1,
                "durationMinutes": 14,
            },
            format="json",
        )

        expected = round(3.5 * 3.5 * 70 / 200 * 14)
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["caloriesBurned"], expected)
        self.assertEqual(
            self.client.get("/api/stats").data["totalCalories"],
            expected,
        )

    def test_calories_are_unavailable_until_weight_is_in_profile(self):
        challenge = Challenge.objects.create(
            user=self.user,
            focus="legs",
            difficulty="beginner",
            start_date=timezone.localdate() - timedelta(days=1),
        )

        response = self.client.post(
            "/api/workouts",
            {
                "focus": "legs",
                "difficulty": "beginner",
                "dayNumber": 1,
                "durationMinutes": 14,
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.assertIsNone(response.data["caloriesBurned"])
        self.assertIsNone(self.client.get("/api/stats").data["totalCalories"])

    def test_stats_sum_only_records_with_calculated_calories(self):
        challenge = Challenge.objects.create(
            user=self.user,
            focus="legs",
            difficulty="beginner",
            start_date=timezone.localdate() - timedelta(days=1),
        )
        first_response = self.client.post(
            "/api/workouts",
            {
                "focus": "legs",
                "difficulty": "beginner",
                "dayNumber": 1,
                "durationMinutes": 10,
            },
            format="json",
        )
        self.assertIsNone(first_response.data["caloriesBurned"])

        profile, _ = UserProfile.objects.get_or_create(user=self.user)
        profile.weight_kg = 70
        profile.save(update_fields=["weight_kg"])
        second_response = self.client.post(
            "/api/workouts",
            {
                "focus": "legs",
                "difficulty": "beginner",
                "dayNumber": 2,
                "durationMinutes": 10,
            },
            format="json",
        )

        expected = round(3.5 * 3.5 * 70 / 200 * 10)
        self.assertEqual(second_response.data["caloriesBurned"], expected)
        self.assertEqual(
            self.client.get("/api/stats").data["totalCalories"],
            expected,
        )

    def test_met_helper_returns_none_without_weight(self):
        self.assertIsNone(estimate_calories_burned(None, 20, "beginner"))

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
