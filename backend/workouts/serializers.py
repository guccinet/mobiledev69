from rest_framework import serializers

from .calorie_estimation import estimate_calories_burned
from .models import UserProfile, WeightEntry


class CompleteWorkoutSerializer(serializers.Serializer):
    focus = serializers.ChoiceField(choices=["abs", "chest", "arms", "legs", "shoulder_back"])
    difficulty = serializers.ChoiceField(
        choices=["beginner", "intermediate", "advanced"]
    )
    dayNumber = serializers.IntegerField(min_value=1, max_value=28)
    durationMinutes = serializers.IntegerField(min_value=1, max_value=300)


class UserProfileSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(source="user.email", read_only=True)
    weightKg = serializers.DecimalField(
        source="weight_kg",
        max_digits=5,
        decimal_places=1,
        min_value=1,
        max_value=500,
        allow_null=True,
        required=False,
    )
    heightCm = serializers.DecimalField(
        source="height_cm",
        max_digits=5,
        decimal_places=1,
        min_value=30,
        max_value=300,
        allow_null=True,
        required=False,
    )
    age = serializers.IntegerField(
        min_value=1,
        max_value=120,
        allow_null=True,
        required=False,
    )
    gender = serializers.ChoiceField(
        choices=UserProfile.GENDER_CHOICES,
        allow_null=True,
        required=False,
    )

    class Meta:
        model = UserProfile
        fields = ["email", "gender", "age", "weightKg", "heightCm"]


class WeightEntrySerializer(serializers.ModelSerializer):
    weightKg = serializers.DecimalField(
        source="weight_kg",
        max_digits=5,
        decimal_places=1,
        min_value=1,
        max_value=500,
    )
    recordedAt = serializers.DateTimeField(source="recorded_at", read_only=True)

    class Meta:
        model = WeightEntry
        fields = ["id", "weightKg", "recordedAt"]
        read_only_fields = ["id", "recordedAt"]


class WorkoutUpdateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=100, trim_whitespace=True)
    durationMinutes = serializers.IntegerField(min_value=1, max_value=300)

    def update(self, instance, validated_data):
        instance.title = validated_data.get("title", instance.title)
        duration = validated_data.get("durationMinutes", instance.duration_minutes)
        instance.duration_minutes = duration
        request = self.context.get("request")
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        instance.calories_burned = estimate_calories_burned(
            profile.weight_kg,
            duration,
            instance.challenge.difficulty,
        )
        instance.save(update_fields=["title", "duration_minutes", "calories_burned"])
        return instance
