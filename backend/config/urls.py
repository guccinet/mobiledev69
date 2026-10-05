from django.contrib.auth import views as auth_views
from django.urls import include, path

from workouts.views import register


urlpatterns = [
    path(
        "accounts/login/",
        auth_views.LoginView.as_view(template_name="registration/login.html"),
        name="login",
    ),
    path(
        "accounts/register/",
        register,
        name="register",
    ),
    path("oidc/", include("oidc_provider.urls", namespace="oidc_provider")),
    path("api/", include("workouts.urls")),
]
