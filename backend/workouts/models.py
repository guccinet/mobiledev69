from django.conf import settings
from django.db import models


class UserProfile(models.Model):
    GENDER_CHOICES = [
        ("male", "ชาย"),
        ("female", "หญิง"),
        ("other", "อื่น ๆ"),
        ("prefer_not_to_say", "ไม่ประสงค์ระบุ"),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="workout_profile",
    )
    gender = models.CharField(
        max_length=24,
        choices=GENDER_CHOICES,
        blank=True,
        null=True,
    )
    age = models.PositiveSmallIntegerField(blank=True, null=True)
    weight_kg = models.DecimalField(
        max_digits=5,
        decimal_places=1,
        blank=True,
        null=True,
    )
    height_cm = models.DecimalField(
        max_digits=5,
        decimal_places=1,
        blank=True,
        null=True,
    )


class Challenge(models.Model):
    FOCUS_CHOICES = [
        ("abs", "Abs"),
        ("chest", "Chest"),
        ("arms", "Arms"),
        ("legs", "Legs"),
        ("shoulder_back", "Shoulder & Back"),
    ]
    DIFFICULTY_CHOICES = [
        ("beginner", "Beginner"),
        ("intermediate", "Intermediate"),
        ("advanced", "Advanced"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="workout_challenges",
    )
    focus = models.CharField(max_length=20, choices=FOCUS_CHOICES)
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_CHOICES)
    start_date = models.DateField()

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "focus", "difficulty"],
                name="unique_user_focus_difficulty_challenge",
            ),
        ]


class Workout(models.Model):
    challenge = models.ForeignKey(
        Challenge,
        on_delete=models.CASCADE,
        related_name="workouts",
    )
    day_number = models.PositiveSmallIntegerField()
    title = models.CharField(max_length=100)
    duration_minutes = models.PositiveSmallIntegerField()
    exercise_count = models.PositiveSmallIntegerField()
    calories_burned = models.PositiveSmallIntegerField()
    completed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-completed_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["challenge", "day_number"],
                name="unique_challenge_workout_day",
            ),
            models.CheckConstraint(
                check=models.Q(day_number__gte=1, day_number__lte=28),
                name="workout_day_is_within_challenge",
            ),
        ]
