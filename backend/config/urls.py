from django.urls import include, path


urlpatterns = [
    path("api/", include("workouts.urls")),
]
