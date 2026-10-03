"""Configuration Django : PFNL."""

from datetime import timedelta
from pathlib import Path

from django.core.exceptions import ImproperlyConfigured
from dotenv import load_dotenv
import logging
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
    logging.getLogger('pfnl.security').warning(
        'SÉCURITÉ : DJANGO_SECRET_KEY absente en production. Une clé de repli dérivée de '
        'variables d’hébergement est utilisée : définissez DJANGO_SECRET_KEY (valeur aléatoire '
        'de 50 caractères ou plus) dans l’environnement Render.'
    )
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
    'config.moderation_images.ModerationImagesMiddleware',
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
        # Connexions réutilisées entre requêtes (sinon chiffrement + authentification à chaque appel).
        'CONN_MAX_AGE': int(os.getenv('DB_CONN_MAX_AGE', '60')),
        'CONN_HEALTH_CHECKS': True,
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

LANGUAGE_CODE = 'fr'
TIME_ZONE = 'Africa/Libreville'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Stockage objet S3 (Cloudflare R2) : copie persistante des médias en production.
# Laisser MEDIA_S3_BUCKET vide en local pour ne jamais écrire dans le bucket de prod.
MEDIA_S3_BUCKET = os.getenv('MEDIA_S3_BUCKET', '').strip()
MEDIA_S3_ENDPOINT_URL = os.getenv('MEDIA_S3_ENDPOINT_URL', '').strip()
MEDIA_S3_ACCESS_KEY_ID = os.getenv('MEDIA_S3_ACCESS_KEY_ID', '').strip()
MEDIA_S3_SECRET_ACCESS_KEY = os.getenv('MEDIA_S3_SECRET_ACCESS_KEY', '').strip()
MEDIA_S3_REGION = os.getenv('MEDIA_S3_REGION', 'auto').strip()
MEDIA_S3_PREFIX = os.getenv('MEDIA_S3_PREFIX', 'media/').strip()

# Modération des images par IA (config/moderation_images.py) : modèle ONNX installé au build.
NSFW_ACTIF = os.getenv('NSFW_ACTIF', 'True').lower() in ('1', 'true', 'yes')
NSFW_SEUIL_DOUTEUX = float(os.getenv('NSFW_SEUIL_DOUTEUX', '0.60'))
NSFW_SEUIL_EXPLICITE = float(os.getenv('NSFW_SEUIL_EXPLICITE', '0.92'))
NSFW_MODELE = os.getenv('NSFW_MODELE', str(BASE_DIR / 'modeles' / 'nsfw-marqo-vit-tiny-384.onnx'))
NSFW_THREADS = int(os.getenv('NSFW_THREADS', '1'))

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

PNLF_FRONTEND_ORIGIN = 'https://plateformedetracabilite-pnlf.netlify.app'
_DEFAULT_CORS_ORIGINS = [
    'http://localhost:4200',
    'http://127.0.0.1:4200',
    PNLF_FRONTEND_ORIGIN,
]
_ENV_CORS = [
    o.strip().rstrip('/')
    for o in os.getenv('CORS_ALLOWED_ORIGINS', '').split(',')
    if o.strip() and o.strip() != '*'
]
# Union env Render + origines Netlify/local (sinon inscription front bloquée).
CORS_ALLOWED_ORIGINS = list(dict.fromkeys(_ENV_CORS + _DEFAULT_CORS_ORIGINS))
CORS_ALLOW_CREDENTIALS = True
CORS_EXPOSE_HEADERS = ['Content-Disposition', 'X-Moderation-Image']
# Aperçus de déploiement Netlify de CE site uniquement (le cookie de refresh est envoyé avec credentials).
CORS_ALLOWED_ORIGIN_REGEXES = [
    r'^https://deploy-preview-\d+--plateformedetracabilite-pnlf\.netlify\.app$',
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

DJANGO_ADMIN_ENABLED = os.getenv('DJANGO_ADMIN_ENABLED', 'False').lower() in ('1', 'true', 'yes')

REST_FRAMEWORK = {
    # Proxys de confiance devant l'application : sur Render, Cloudflare puis le répartiteur Render (2).
    # Sert au throttling et au journal ; sans X-Forwarded-For (local), REMOTE_ADDR est utilisé.
    'NUM_PROXIES': int(os.getenv('DRF_NUM_PROXIES', '2')),
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
        'refresh': '30/min',
        'contact_public': '5/min',
        'inscription_public': '5/min',
        'password_reset': '5/min',
    },
    'DEFAULT_PAGINATION_CLASS': 'config.pagination.StandardResultsPagination',
    'PAGE_SIZE': 25,
    'EXCEPTION_HANDLER': 'config.exceptions.gestionnaire_exceptions',
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
