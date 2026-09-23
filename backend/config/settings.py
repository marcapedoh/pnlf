"""Configuration Django — PFNL."""

from datetime import timedelta
from pathlib import Path

from django.core.exceptions import ImproperlyConfigured
from dotenv import load_dotenv
import os

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / '.env')
# En local, .env.local (PostgreSQL 127.0.0.1) prime sur .env (ex. Render)
load_dotenv(BASE_DIR / '.env.local', override=True)

DEBUG = os.getenv('DJANGO_DEBUG', 'False').lower() in ('1', 'true', 'yes')


def _resolve_secret_key() -> str:
    """DJANGO_SECRET_KEY / SECRET_KEY, sinon dérivation stable Render (évite crash au boot)."""
    import hashlib

    for key in ('DJANGO_SECRET_KEY', 'SECRET_KEY'):
        val = (os.getenv(key) or '').strip()
        if val and val not in ('insecure-dev-key', 'change-me'):
            return val
    if DEBUG:
        return 'insecure-dev-key'
    # Render injecte toujours RENDER_SERVICE_ID + DATABASE_URL
    material = '|'.join(
        [
            os.getenv('RENDER_SERVICE_ID', ''),
            os.getenv('DATABASE_URL', ''),
            os.getenv('DB_PASSWORD', ''),
            'pfnl-prod',
        ]
    )
    if material.replace('|', ''):
        return hashlib.sha256(material.encode('utf-8')).hexdigest()
    raise ImproperlyConfigured(
        'Définissez DJANGO_SECRET_KEY dans les variables d’environnement Render '
        '(Environment → Add Environment Variable).'
    )


SECRET_KEY = _resolve_secret_key()
ALLOWED_HOSTS = [
    h.strip()
    for h in os.getenv(
        'DJANGO_ALLOWED_HOSTS',
        'localhost,127.0.0.1,testserver,.onrender.com,pfnl.onrender.com',
    ).split(',')
    if h.strip()
]

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # tiers
    'corsheaders',
    'rest_framework',
    'rest_framework_simplejwt',
    'django_filters',
    # apps PNLF
    'accounts',
    'traceability',
    'pnlf_platform',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'pnlf'),
        'USER': os.getenv('DB_USER', 'pnlf_app'),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': os.getenv('DB_HOST', '127.0.0.1'),
        'PORT': os.getenv('DB_PORT', '5432'),
        'OPTIONS': {
            # public en premier = tables Django ; pnlf = tables métier
            'options': '-c search_path=public,pnlf',
        },
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE = 'Africa/Libreville'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

_DEFAULT_CORS_ORIGINS = [
    'http://localhost:4200',
    'http://127.0.0.1:4200',
    'https://platformedetracabilite-pnlf.netlify.app',
    'https://platformedetracabilite-pnfl.netlify.app',
]
_ENV_CORS = [
    o.strip()
    for o in os.getenv('CORS_ALLOWED_ORIGINS', '').split(',')
    if o.strip()
]
# Union env Render + origines Netlify/local (sinon inscription front bloquée).
CORS_ALLOWED_ORIGINS = list(dict.fromkeys(_ENV_CORS + _DEFAULT_CORS_ORIGINS))
CORS_ALLOW_CREDENTIALS = True
CORS_EXPOSE_HEADERS = ['Content-Disposition']
CORS_ALLOWED_ORIGIN_REGEXES = [
    r'^https://.*\.netlify\.app$',
]

# Sécurité production
if not DEBUG:
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    X_FRAME_OPTIONS = 'DENY'
    SECURE_SSL_REDIRECT = os.getenv('DJANGO_SECURE_SSL_REDIRECT', 'True').lower() in ('1', 'true', 'yes')
    SECURE_HSTS_SECONDS = int(os.getenv('DJANGO_SECURE_HSTS_SECONDS', '31536000'))
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    _csrf_env = [
        o.strip()
        for o in os.getenv('CSRF_TRUSTED_ORIGINS', '').split(',')
        if o.strip()
    ]
    CSRF_TRUSTED_ORIGINS = list(
        dict.fromkeys(
            _csrf_env
            + [o for o in CORS_ALLOWED_ORIGINS if o.startswith('https://')]
            + ['https://pfnl.onrender.com']
        )
    )

PNLF_PUBLIC_VERIFY_URL = os.getenv('PNLF_PUBLIC_VERIFY_URL', 'http://localhost:8000/api/verify/')
PNLF_FRONTEND_URL = os.getenv('PNLF_FRONTEND_URL', 'http://localhost:4200')

# --- Envoi d'e-mails (inscription, validation, mot de passe) ------------------
EMAIL_BACKEND = os.getenv('DJANGO_EMAIL_BACKEND', 'django.core.mail.backends.console.EmailBackend')
EMAIL_HOST = os.getenv('EMAIL_HOST', '')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', '587'))
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD', '')
EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS', 'True').lower() in ('1', 'true', 'yes')
EMAIL_USE_SSL = os.getenv('EMAIL_USE_SSL', 'False').lower() in ('1', 'true', 'yes')
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL', 'PFNL <no-reply@pnlf.ga>')
EMAIL_TIMEOUT = 10

# --- Envoi de SMS (Twilio) -----------------------------------------------------
TWILIO_ACCOUNT_SID = os.getenv('TWILIO_ACCOUNT_SID', '')
TWILIO_AUTH_TOKEN = os.getenv('TWILIO_AUTH_TOKEN', '')
TWILIO_FROM_NUMBER = os.getenv('TWILIO_FROM_NUMBER', '')

AUTHENTICATION_BACKENDS = [
    'accounts.backends.PnlfAuthBackend',
    'django.contrib.auth.backends.ModelBackend',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'accounts.authentication.PnlfJWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_FILTER_BACKENDS': (
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ),
    'DEFAULT_THROTTLE_CLASSES': (
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ),
    'DEFAULT_THROTTLE_RATES': {
        'anon': '60/min',
        'user': '300/min',
        'login': '8/min',
        'contact_public': '5/min',
        'inscription_public': '5/min',
        'password_reset': '5/min',
    },
    'DEFAULT_PAGINATION_CLASS': 'config.pagination.StandardResultsPagination',
    'PAGE_SIZE': 25,
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    # Pas de token_blacklist : AUTH_USER_MODEL n'est pas Utilisateur (UUID métier).
    # Révocation via empreinte mot de passe (claim pwd) + cookie HttpOnly.
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': False,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
}

# Cookie HttpOnly pour le refresh JWT (SEC-04)
PNLF_REFRESH_COOKIE = 'pfnl_refresh'
PNLF_REFRESH_COOKIE_PATH = '/api/auth/'
PNLF_REFRESH_COOKIE_SAMESITE = os.getenv('PNLF_REFRESH_COOKIE_SAMESITE', 'Lax' if DEBUG else 'None')
PNLF_REFRESH_COOKIE_SECURE = not DEBUG
