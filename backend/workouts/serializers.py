from django.contrib.auth import authenticate, get_user_model
from rest_framework import serializers

from .models import UserProfile


User = get_user_model()


class CredentialsSerializer(serializers.Serializer):
    email = serializers.EmailField(max_length=150)
    password = serializers.CharField(
        write_only=True,
        trim_whitespace=False,
        min_length=8,
    )


class RegistrationSerializer(CredentialsSerializer):
    def validate_email(self, value):
        normalized = value.strip().lower()
        if User.objects.filter(username=normalized).exists():
            raise serializers.ValidationError("อีเมลนี้ถูกใช้งานแล้ว")
        return normalized

    def create(self, validated_data):
        return User.objects.create_user(
            username=validated_data["email"],
            email=validated_data["email"],
            password=validated_data["password"],
        )


class LoginSerializer(CredentialsSerializer):
    def validate(self, attrs):
        email = attrs["email"].strip().lower()
        user = authenticate(
            request=self.context.get("request"),
            username=email,
            password=attrs["password"],
        )
        if user is None:
            raise serializers.ValidationError(
                {"detail": "อีเมลหรือรหัสผ่านไม่ถูกต้อง"}
            )
        attrs["user"] = user
        return attrs


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
