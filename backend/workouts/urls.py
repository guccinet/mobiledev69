from django.urls import path

from .views import (
    ExerciseListView,
    HealthView,
    LoginView,
    LogoutView,
    PlanView,
    ProfileView,
    RegisterView,
    StatsView,
    WorkoutListView,
)


urlpatterns = [
    path("health", HealthView.as_view(), name="health"),
    path("auth/register", RegisterView.as_view(), name="register"),
    path("auth/login", LoginView.as_view(), name="login"),
    path("auth/logout", LogoutView.as_view(), name="logout"),
    path("profile", ProfileView.as_view(), name="profile"),
    path("exercises", ExerciseListView.as_view(), name="exercises"),
    path("plan", PlanView.as_view(), name="plan"),
    path("workouts", WorkoutListView.as_view(), name="workouts"),
    path("stats", StatsView.as_view(), name="stats"),
]
