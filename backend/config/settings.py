
"""Configuration Django : PFNL."""

import logging
import os
import hashlib

from datetime import timedelta
from pathlib import Path

from django.core.exceptions import ImproperlyConfigured
from dotenv import load_dotenv


# ============================================================
# BASE CONFIGURATION
# ============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

load_dotenv(BASE_DIR / ".env")

# En local, .env.local prime sur .env.
# Attention : ne pas embarquer ce fichier dans un déploiement production.
if os.getenv("DJANGO_ENV", "").lower() != "production":
    load_dotenv(BASE_DIR / ".env.local", override=True)

DEBUG = os.getenv("DJANGO_DEBUG", "False").lower() in (
    "1", "true", "yes"
)


# ============================================================
# SECRET KEY
# ============================================================

def _resolve_secret_key() -> str:
    """Récupère une clé secrète Django sécurisée."""

    for key in ("DJANGO_SECRET_KEY", "SECRET_KEY"):
        val = (os.getenv(key) or "").strip()

        if val and val not in ("insecure-dev-key", "change-me"):
            return val

    if DEBUG:
        return "insecure-dev-key"

    raise ImproperlyConfigured(
        "DJANGO_SECRET_KEY doit être définie en production. "
        "Générez une clé aléatoire d'au moins 50 caractères."
    )


SECRET_KEY = _resolve_secret_key()


# ============================================================
# ALLOWED HOSTS
# ============================================================

ALLOWED_HOSTS = [
    host.strip().lower()
    for host in os.getenv(
        "DJANGO_ALLOWED_HOSTS",
        "localhost,127.0.0.1,testserver,.onrender.com,pfnl.onrender.com"
    ).split(",")
    if host.strip()
]


# ============================================================
# FRONTEND ORIGINS
# ============================================================

PNLF_FRONTEND_ORIGIN = (
    "https://plateformedetracabilite-pnlf.netlify.app"
)

_DEFAULT_CORS_ORIGINS = [
    "http://localhost:4200",
    "http://127.0.0.1:4200",
    PNLF_FRONTEND_ORIGIN,
]

_ENV_CORS = [
    origin.strip().rstrip("/")
    for origin in os.getenv(
        "CORS_ALLOWED_ORIGINS", ""
    ).split(",")
    if origin.strip() and origin.strip() != "*"
]

CORS_ALLOWED_ORIGINS = list(
    dict.fromkeys(_ENV_CORS + _DEFAULT_CORS_ORIGINS)
)

CORS_ALLOW_CREDENTIALS = True

CORS_EXPOSE_HEADERS = [
    "Content-Disposition",
    "X-Moderation-Image",
]

# Déploiements Preview Netlify du projet PFNL
# Tunnels Cloudflare temporaires
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^https://deploy-preview-\d+--plateformedetracabilite-pnlf\.netlify\.app$",
    r"^https://[a-zA-Z0-9-]+\.trycloudflare\.com$",
]


# ============================================================
# CSRF TRUSTED ORIGINS
# ============================================================

_csrf_env = [
    origin.strip().rstrip("/")
    for origin in os.getenv(
        "CSRF_TRUSTED_ORIGINS", ""
    ).split(",")
    if origin.strip()
]

CSRF_TRUSTED_ORIGINS = list(
    dict.fromkeys(
        _csrf_env
        + [
            origin
            for origin in CORS_ALLOWED_ORIGINS
            if origin.startswith("https://")
        ]
        + [
            "https://*.trycloudflare.com",
            "https://pfnl.onrender.com",
        ]
    )
)


# ============================================================
# INSTALLED APPLICATIONS
# ============================================================

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",

    # Applications tierces
    "corsheaders",
    "rest_framework",
    "rest_framework_simplejwt",
    "django_filters",

    # Applications PFNL
    "accounts",
    "traceability",
    "pnlf_platform",
]


# ============================================================
# MIDDLEWARE
# ============================================================

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "config.moderation_images.ModerationImagesMiddleware",
]


# ============================================================
# URLS AND TEMPLATES
# ============================================================

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"


# ============================================================
# DATABASE - POSTGRESQL
# ============================================================

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("DB_NAME", "pnlf"),
        "USER": os.getenv("DB_USER", "pnlf_app"),
        "PASSWORD": os.getenv("DB_PASSWORD", ""),
        "HOST": os.getenv("DB_HOST", "127.0.0.1"),
        "PORT": os.getenv("DB_PORT", "5432"),

        "CONN_MAX_AGE": int(
            os.getenv("DB_CONN_MAX_AGE", "60")
        ),

        "CONN_HEALTH_CHECKS": True,

        "OPTIONS": {
            "options": "-c search_path=public,pnlf",
        },
    }
}


# ============================================================
# PASSWORD VALIDATION
# ============================================================

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME":
        "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"
    },
    {
        "NAME":
        "django.contrib.auth.password_validation.MinimumLengthValidator"
    },
    {
        "NAME":
        "django.contrib.auth.password_validation.CommonPasswordValidator"
    },
    {
        "NAME":
        "django.contrib.auth.password_validation.NumericPasswordValidator"
    },
]


# ============================================================
# INTERNATIONALIZATION
# ============================================================

LANGUAGE_CODE = "fr"

TIME_ZONE = "Africa/Libreville"

USE_I18N = True

USE_TZ = True


# ============================================================
# STATIC AND MEDIA FILES
# ============================================================

STATIC_URL = "/static/"

STATIC_ROOT = BASE_DIR / "staticfiles"

MEDIA_URL = "/media/"

MEDIA_ROOT = BASE_DIR / "media"


# ============================================================
# CLOUDFLARE R2 - OBJECT STORAGE
# ============================================================

MEDIA_S3_BUCKET = os.getenv(
    "MEDIA_S3_BUCKET", ""
).strip()

MEDIA_S3_ENDPOINT_URL = os.getenv(
    "MEDIA_S3_ENDPOINT_URL", ""
).strip()

MEDIA_S3_ACCESS_KEY_ID = os.getenv(
    "MEDIA_S3_ACCESS_KEY_ID", ""
).strip()

MEDIA_S3_SECRET_ACCESS_KEY = os.getenv(
    "MEDIA_S3_SECRET_ACCESS_KEY", ""
).strip()

MEDIA_S3_REGION = os.getenv(
    "MEDIA_S3_REGION", "auto"
).strip()

MEDIA_S3_PREFIX = os.getenv(
    "MEDIA_S3_PREFIX", "media/"
).strip()


# ============================================================
# AI IMAGE MODERATION
# ============================================================

NSFW_ACTIF = os.getenv(
    "NSFW_ACTIF", "True"
).lower() in ("1", "true", "yes")

NSFW_SEUIL_DOUTEUX = float(
    os.getenv("NSFW_SEUIL_DOUTEUX", "0.60")
)

NSFW_SEUIL_EXPLICITE = float(
    os.getenv("NSFW_SEUIL_EXPLICITE", "0.92")
)

NSFW_MODELE = os.getenv(
    "NSFW_MODELE",
    str(BASE_DIR / "modeles" / "nsfw-marqo-vit-tiny-384.onnx")
)

NSFW_THREADS = int(
    os.getenv("NSFW_THREADS", "1")
)


# ============================================================
# DEFAULT MODEL FIELD
# ============================================================

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"


# ============================================================
# PRODUCTION SECURITY
# ============================================================

if not DEBUG:

    SECURE_CONTENT_TYPE_NOSNIFF = True

    X_FRAME_OPTIONS = "DENY"

    SESSION_COOKIE_SECURE = True

    CSRF_COOKIE_SECURE = True

    SECURE_SSL_REDIRECT = (
        os.getenv(
            "DJANGO_SECURE_SSL_REDIRECT", "True"
        ).lower() in ("1", "true", "yes")
    )

    SECURE_PROXY_SSL_HEADER = (
        "HTTP_X_FORWARDED_PROTO",
        "https",
    )

    # HSTS
    SECURE_HSTS_SECONDS = int(
        os.getenv("DJANGO_SECURE_HSTS_SECONDS", "31536000")
    )

    # Ne pas activer sur un domaine mutualisé.
    SECURE_HSTS_INCLUDE_SUBDOMAINS = False

    SECURE_HSTS_PRELOAD = False


# ============================================================
# PUBLIC FRONTEND URLS
# ============================================================

PNLF_PUBLIC_VERIFY_URL = os.getenv(
    "PNLF_PUBLIC_VERIFY_URL",
    "http://localhost:8000/api/verify/"
)

PNLF_FRONTEND_URL = os.getenv(
    "PNLF_FRONTEND_URL",
    "http://localhost:4200"
).rstrip("/")


# ============================================================
# EMAIL CONFIGURATION
# ============================================================

EMAIL_BACKEND = os.getenv(
    "DJANGO_EMAIL_BACKEND",
    "django.core.mail.backends.console.EmailBackend"
)

EMAIL_HOST = os.getenv("EMAIL_HOST", "")

EMAIL_PORT = int(os.getenv("EMAIL_PORT", "587"))

EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER", "")

EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD", "")

EMAIL_USE_TLS = os.getenv(
    "EMAIL_USE_TLS", "True"
).lower() in ("1", "true", "yes")

EMAIL_USE_SSL = os.getenv(
    "EMAIL_USE_SSL", "False"
).lower() in ("1", "true", "yes")

DEFAULT_FROM_EMAIL = os.getenv(
    "DEFAULT_FROM_EMAIL",
    "PFNL <no-reply@pnlf.ga>"
)

EMAIL_TIMEOUT = 10


# ============================================================
# SMS - TWILIO
# ============================================================

TWILIO_ACCOUNT_SID = os.getenv(
    "TWILIO_ACCOUNT_SID", ""
)

TWILIO_AUTH_TOKEN = os.getenv(
    "TWILIO_AUTH_TOKEN", ""
)

TWILIO_FROM_NUMBER = os.getenv(
    "TWILIO_FROM_NUMBER", ""
)


# ============================================================
# AUTHENTICATION BACKENDS
# ============================================================

AUTHENTICATION_BACKENDS = [
    "accounts.backends.PnlfAuthBackend",
    "django.contrib.auth.backends.ModelBackend",
]


# ============================================================
# DJANGO ADMIN
# ============================================================

DJANGO_ADMIN_ENABLED = os.getenv(
    "DJANGO_ADMIN_ENABLED", "False"
).lower() in ("1", "true", "yes")


# ============================================================
# DJANGO REST FRAMEWORK
# ============================================================

REST_FRAMEWORK = {

    "NUM_PROXIES": int(
        os.getenv("DRF_NUM_PROXIES", "2")
    ),

    "DEFAULT_AUTHENTICATION_CLASSES": (
        "accounts.authentication.PnlfJWTAuthentication",
    ),

    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),

    "DEFAULT_FILTER_BACKENDS": (
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.SearchFilter",
        "rest_framework.filters.OrderingFilter",
    ),

    "DEFAULT_THROTTLE_CLASSES": (
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ),

    "DEFAULT_THROTTLE_RATES": {
        "anon": "60/min",
        "user": "300/min",
        "login": "8/min",
        "refresh": "30/min",
        "contact_public": "5/min",
        "inscription_public": "5/min",
        "password_reset": "5/min",
    },

    "DEFAULT_PAGINATION_CLASS":
        "config.pagination.StandardResultsPagination",

    "PAGE_SIZE": 25,

    "EXCEPTION_HANDLER":
        "config.exceptions.gestionnaire_exceptions",
}


# ============================================================
# JWT CONFIGURATION
# ============================================================

SIMPLE_JWT = {

    "ACCESS_TOKEN_LIFETIME": timedelta(hours=1),

    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),

    "ROTATE_REFRESH_TOKENS": False,

    "BLACKLIST_AFTER_ROTATION": False,

    "AUTH_HEADER_TYPES": ("Bearer",),

    "USER_ID_FIELD": "id",

    "USER_ID_CLAIM": "user_id",
}


# ============================================================
# JWT REFRESH COOKIE - SEC-04
# ============================================================

PNLF_REFRESH_COOKIE = "pfnl_refresh"

PNLF_REFRESH_COOKIE_PATH = "/api/auth/"

PNLF_REFRESH_COOKIE_SAMESITE = os.getenv(
    "PNLF_REFRESH_COOKIE_SAMESITE",
    "Lax" if DEBUG else "None"
)

PNLF_REFRESH_COOKIE_SECURE = not DEBUG

# Les cookies cross-site nécessitent SameSite=None et Secure.
if PNLF_REFRESH_COOKIE_SAMESITE.lower() == "none":
    PNLF_REFRESH_COOKIE_SECURE = True

# Le navigateur doit pouvoir envoyer le cookie dans les requêtes
# cross-origin lorsque les conditions de sécurité sont réunies.
CSRF_COOKIE_SAMESITE = os.getenv(
    "CSRF_COOKIE_SAMESITE",
    "None" if not DEBUG else "Lax"
)

SESSION_COOKIE_SAMESITE = os.getenv(
    "SESSION_COOKIE_SAMESITE",
    "None" if not DEBUG else "Lax"
)
