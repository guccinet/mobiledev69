from django.urls import path

from .views import (
    ExerciseListView,
    HealthView,
    PlanView,
    ProfileView,
    StatsView,
    WeightHistoryView,
    WorkoutListView,
    WorkoutDetailView,
)


urlpatterns = [
    path("health", HealthView.as_view(), name="health"),
    path("profile", ProfileView.as_view(), name="profile"),
    path("weights", WeightHistoryView.as_view(), name="weight-history"),
    path("exercises", ExerciseListView.as_view(), name="exercises"),
    path("plan", PlanView.as_view(), name="plan"),
    path("workouts", WorkoutListView.as_view(), name="workouts"),
    path("workouts/<int:workout_id>", WorkoutDetailView.as_view(), name="workout-detail"),
    path("stats", StatsView.as_view(), name="stats"),
]
