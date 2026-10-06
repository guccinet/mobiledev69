import os
from pathlib import Path

import dj_database_url
from django.core.exceptions import ImproperlyConfigured


BASE_DIR = Path(__file__).resolve().parent.parent
DEBUG = os.environ.get("DJANGO_DEBUG", "1") == "1"
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "dev-only-change-me")
if not DEBUG and (not SECRET_KEY or SECRET_KEY == "dev-only-change-me"):
    raise ImproperlyConfigured("DJANGO_SECRET_KEY must be set when DEBUG is disabled.")

RENDER_EXTERNAL_HOSTNAME = os.environ.get("RENDER_EXTERNAL_HOSTNAME")
PUBLIC_ORIGIN = os.environ.get("PUBLIC_ORIGIN") or (
    f"https://{RENDER_EXTERNAL_HOSTNAME}"
    if RENDER_EXTERNAL_HOSTNAME
    else "http://localhost:3000"
)
ALLOWED_HOSTS = [
    host.strip()
    for host in os.environ.get(
        "DJANGO_ALLOWED_HOSTS",
        ",".join(
            filter(
                None,
                ["localhost", "127.0.0.1", "10.0.2.2", RENDER_EXTERNAL_HOSTNAME],
            )
        ),
    ).split(",")
    if host.strip()
]

INSTALLED_APPS = [
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "rest_framework",
    "oidc_provider",
    "workouts",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "workouts.middleware.RequirePublicClientPKCE",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "workouts" / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]
WSGI_APPLICATION = "config.wsgi.application"
LOGIN_URL = "/accounts/login/"
LOGIN_REDIRECT_URL = "/"
SITE_URL = os.environ.get("OIDC_ISSUER_URL", PUBLIC_ORIGIN).rstrip("/")
OIDC_SITE_URL = SITE_URL
OIDC_IDTOKEN_INCLUDE_CLAIMS = True
OIDC_FLUTTER_CLIENT_ID = os.environ.get(
    "OIDC_FLUTTER_CLIENT_ID",
    "movedaily-flutter",
)
OIDC_REDIRECT_URI = os.environ.get(
    "OIDC_REDIRECT_URI",
    (
        f"{PUBLIC_ORIGIN}/static/app/redirect.html"
        if RENDER_EXTERNAL_HOSTNAME
        else "http://localhost:50000/redirect.html"
    ),
)

DATABASE_URL = os.environ.get("DATABASE_URL")
DATABASES = (
    {
        "default": dj_database_url.parse(
            DATABASE_URL,
            conn_max_age=600,
            ssl_require=not DEBUG,
        )
    }
    if DATABASE_URL
    else {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }
)

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "th"
TIME_ZONE = "Asia/Bangkok"
USE_I18N = True
USE_TZ = True
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
FRONTEND_BUILD_DIR = BASE_DIR / "frontend_build" / "app"
STATICFILES_DIRS = (
    [BASE_DIR / "frontend_build"]
    if (BASE_DIR / "frontend_build").is_dir()
    else []
)
STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {
        "BACKEND": (
            "whitenoise.storage.CompressedStaticFilesStorage"
            if not DEBUG
            else "django.contrib.staticfiles.storage.StaticFilesStorage"
        )
    },
}
DEFAULT_AUTO_FIELD = "django.db.models.AutoField"

CORS_ALLOW_ALL_ORIGINS = DEBUG
CORS_ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.environ.get("CORS_ALLOWED_ORIGINS", "").split(",")
    if origin.strip()
]

if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 3600
    CSRF_TRUSTED_ORIGINS = [PUBLIC_ORIGIN]

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "workouts.authentication.OIDCAccessTokenAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_RENDERER_CLASSES": [
        "rest_framework.renderers.JSONRenderer",
    ],
}
