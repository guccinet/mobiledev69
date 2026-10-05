from django import forms
from django.contrib.auth import get_user_model, password_validation
from django.core.exceptions import ValidationError

from .models import UserProfile, WeightEntry


class RegistrationForm(forms.Form):
    email = forms.EmailField(
        label="อีเมล",
        max_length=254,
        widget=forms.EmailInput(
            attrs={"autocomplete": "email", "required": True}
        ),
    )
    gender = forms.ChoiceField(
        label="เพศ",
        choices=[("", "เลือกได้ หรือเว้นว่าง")] + UserProfile.GENDER_CHOICES,
        required=False,
    )
    age = forms.IntegerField(
        label="อายุ (ปี)",
        min_value=1,
        max_value=120,
        required=False,
        widget=forms.NumberInput(attrs={"min": 1, "max": 120}),
    )
    weight_kg = forms.DecimalField(
        label="น้ำหนัก (กก.)",
        min_value=1,
        max_value=500,
        max_digits=5,
        decimal_places=1,
        required=False,
        widget=forms.NumberInput(attrs={"min": 1, "max": 500, "step": "0.1"}),
    )
    height_cm = forms.DecimalField(
        label="ส่วนสูง (ซม.)",
        min_value=30,
        max_value=300,
        max_digits=5,
        decimal_places=1,
        required=False,
        widget=forms.NumberInput(attrs={"min": 30, "max": 300, "step": "0.1"}),
    )
    password1 = forms.CharField(
        label="รหัสผ่าน",
        strip=False,
        widget=forms.PasswordInput(
            attrs={"autocomplete": "new-password", "required": True}
        ),
    )
    password2 = forms.CharField(
        label="ยืนยันรหัสผ่าน",
        strip=False,
        widget=forms.PasswordInput(
            attrs={"autocomplete": "new-password", "required": True}
        ),
    )

    def clean_email(self):
        email = self.cleaned_data["email"].strip().lower()
        user_model = get_user_model()
        if user_model.objects.filter(username__iexact=email).exists():
            raise ValidationError("อีเมลนี้ถูกใช้สมัครบัญชีแล้ว")
        if user_model.objects.filter(email__iexact=email).exists():
            raise ValidationError("อีเมลนี้ถูกใช้สมัครบัญชีแล้ว")
        return email

    def clean(self):
        cleaned_data = super().clean()
        password1 = cleaned_data.get("password1")
        password2 = cleaned_data.get("password2")
        if password1 and password2 and password1 != password2:
            self.add_error("password2", "รหัสผ่านทั้งสองช่องไม่ตรงกัน")
        if password1 and "email" in cleaned_data:
            user_model = get_user_model()
            user = user_model(
                username=cleaned_data["email"],
                email=cleaned_data["email"],
            )
            try:
                password_validation.validate_password(password1, user=user)
            except ValidationError as error:
                self.add_error("password1", error)
        return cleaned_data

    def save(self):
        if not self.is_valid():
            raise ValueError("RegistrationForm must be valid before saving.")
        user_model = get_user_model()
        email = self.cleaned_data["email"]
        user = user_model.objects.create_user(
            username=email,
            email=email,
            password=self.cleaned_data["password1"],
        )
        profile = UserProfile.objects.create(
            user=user,
            gender=self.cleaned_data["gender"] or None,
            age=self.cleaned_data["age"],
            weight_kg=self.cleaned_data["weight_kg"],
            height_cm=self.cleaned_data["height_cm"],
        )
        if profile.weight_kg is not None:
            WeightEntry.objects.create(user=user, weight_kg=profile.weight_kg)
        return user
