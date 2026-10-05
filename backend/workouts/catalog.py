from datetime import timedelta

from django.utils import timezone

from .models import Challenge


FOCUS_LABELS = dict(Challenge.FOCUS_CHOICES)
DIFFICULTY_LABELS = dict(Challenge.DIFFICULTY_CHOICES)
BASE_ROUTINES = {
    "abs": [
        ("crunches", "Crunches", "หน้าท้อง", "reps", 15),
        ("bicycle-crunch", "Bicycle Crunches", "หน้าท้อง", "reps", 16),
        ("leg-raises", "Leg Raises", "หน้าท้อง", "reps", 12),
        ("plank", "Plank", "หน้าท้อง", "seconds", 30),
        ("mountain-climbers", "Mountain Climbers", "หน้าท้อง", "reps", 20),
        ("dead-bug", "Dead Bug", "หน้าท้อง", "reps", 16),
    ],
    "chest": [
        ("push-ups", "Push-ups", "หน้าอก", "reps", 12),
        ("wide-push-ups", "Wide Push-ups", "หน้าอก", "reps", 10),
        ("incline-push-ups", "Incline Push-ups", "หน้าอก", "reps", 12),
        ("diamond-push-ups", "Diamond Push-ups", "หน้าอก", "reps", 8),
        ("shoulder-taps", "Shoulder Taps", "หน้าอก", "reps", 20),
        ("knee-push-ups", "Knee Push-ups", "หน้าอก", "reps", 12),
    ],
    "arms": [
        ("triceps-dips", "Triceps Dips", "แขน", "reps", 12),
        ("pike-push-ups", "Pike Push-ups", "แขน", "reps", 8),
        ("arm-circles", "Arm Circles", "แขน", "seconds", 30),
        ("plank-up-downs", "Plank Up-Downs", "แขน", "reps", 10),
        ("close-grip-push-ups", "Close-grip Push-ups", "แขน", "reps", 8),
        ("wall-push-ups", "Wall Push-ups", "แขน", "reps", 15),
    ],
    "legs": [
        ("squats", "Squats", "ขา", "reps", 20),
        ("reverse-lunges", "Reverse Lunges", "ขา", "reps", 12),
        ("glute-bridges", "Glute Bridges", "ขา", "reps", 15),
        ("calf-raises", "Calf Raises", "ขา", "reps", 20),
        ("wall-sit", "Wall Sit", "ขา", "seconds", 30),
        ("sumo-squats", "Sumo Squats", "ขา", "reps", 16),
    ],
    "shoulder_back": [
        ("superman", "Superman", "ไหล่และหลัง", "reps", 12),
        ("reverse-snow-angels", "Reverse Snow Angels", "ไหล่และหลัง", "reps", 12),
        ("bird-dog", "Bird Dog", "ไหล่และหลัง", "reps", 16),
        ("cobra-stretch", "Cobra Stretch", "ไหล่และหลัง", "seconds", 30),
        ("swimmers", "Swimmers", "ไหล่และหลัง", "seconds", 30),
        ("pike-hold", "Pike Hold", "ไหล่และหลัง", "seconds", 20),
    ],
}
DIFFICULTY_MULTIPLIERS = {
    "beginner": 1.0,
    "intermediate": 1.35,
    "advanced": 1.7,
}
REST_EXERCISE = {
    "id": "recovery-stretch",
    "name": "Recovery Stretch",
    "focus": "ยืดเหยียดฟื้นฟู",
    "durationSeconds": 300,
    "level": "ทุกระดับ",
    "sets": 1,
    "repetitions": 300,
    "unit": "seconds",
}


def exercise_catalog(focus, difficulty):
    multiplier = DIFFICULTY_MULTIPLIERS[difficulty]
    result = []
    for exercise_id, name, label, unit, amount in BASE_ROUTINES[focus]:
        scaled_amount = max(5, round(amount * multiplier))
        result.append(
            {
                "id": exercise_id,
                "name": name,
                "focus": label,
                "durationSeconds": scaled_amount if unit == "seconds" else 40,
                "level": DIFFICULTY_LABELS[difficulty],
                "sets": 3 if difficulty == "beginner" else 4,
                "repetitions": scaled_amount,
                "unit": unit,
            }
        )
    return result


def make_plan(challenge):
    exercises = exercise_catalog(challenge.focus, challenge.difficulty)
    completed_days = set(challenge.workouts.values_list("day_number", flat=True))
    elapsed_days = max(1, (timezone.localdate() - challenge.start_date).days + 1)
    current_day = min(elapsed_days, 28)
    days = []
    completed_training_streak = 0

    for day_number in range(1, 29):
        scheduled_rest = day_number % 7 == 0
        recovery_rest = not scheduled_rest and completed_training_streak >= 3
        is_rest_day = scheduled_rest or recovery_rest

        if is_rest_day:
            day_exercises = [REST_EXERCISE]
            title = (
                "วันพักฟื้นหลังฝึกต่อเนื่อง"
                if recovery_rest
                else "วันพักและยืดเหยียด"
            )
            completed_training_streak = 0
        else:
            rotation = (day_number - 1) % len(exercises)
            day_exercises = [
                exercises[(rotation + offset) % len(exercises)]
                for offset in range(4)
            ]
            title = f"{FOCUS_LABELS[challenge.focus]} · วันที่ {day_number}"
            if day_number in completed_days:
                completed_training_streak += 1
            else:
                completed_training_streak = 0

        days.append(
            {
                "dayNumber": day_number,
                "date": (challenge.start_date + timedelta(days=day_number - 1)).isoformat(),
                "title": title,
                "isCompleted": day_number in completed_days,
                "isAvailable": day_number <= current_day,
                "isRestDay": is_rest_day,
                "exercises": day_exercises,
            }
        )

    return {
        "focus": challenge.focus,
        "focusLabel": FOCUS_LABELS[challenge.focus],
        "difficulty": challenge.difficulty,
        "difficultyLabel": DIFFICULTY_LABELS[challenge.difficulty],
        "startDate": challenge.start_date.isoformat(),
        "currentDay": current_day,
        "days": days,
    }


def get_or_create_challenge(user, focus, difficulty):
    challenge, _ = Challenge.objects.get_or_create(
        user=user,
        focus=focus,
        difficulty=difficulty,
        defaults={"start_date": timezone.localdate()},
    )
    return challenge
