// =============================================================================
// PFNL — Déploiement isolé du backend Django
//   pfnl-db (PostgreSQL 18 + PostGIS)  <-- réseau privé pfnl-net -->  pfnl-backend  <--  pfnl-tunnel (Cloudflare)
// Aucun port publié sur l'hôte : tout passe par le tunnel Cloudflare dédié.
// Secrets : en dur dans PFNL_ENV_CONTENT ci-dessous
// =============================================================================

// =============================================================================
// Variables de production EN DUR (le dépôt doit rester privé).
// Format docker --env-file : une variable par ligne, sans guillemets.
// À compléter : domaine, TUNNEL_TOKEN, R2, e-mail, Twilio.
// =============================================================================
def PFNL_ENV_CONTENT = '''
DJANGO_DEBUG=False
DJANGO_SECRET_KEY=g13KbEVubD03iaDYPvCUPeEgscXfiEGLi6TbBkAW9rWi7-wSh2GNaaSLzRulzJLReVukCRvtPu_zn5Cp8l-ljw
DJANGO_ALLOWED_HOSTS=.trycloudflare.com,localhost,127.0.0.1,https://pfnl-ndjila.netlify.app/
CSRF_TRUSTED_ORIGINS=https://*.trycloudflare.com
CORS_ALLOWED_ORIGINS=https://pfnl-ndjila.netlify.app/
DJANGO_SECURE_SSL_REDIRECT=False
DJANGO_ADMIN_ENABLED=False
DRF_NUM_PROXIES=1
PNLF_FRONTEND_URL=https://pfnl-ndjila.netlify.app/

DB_NAME=pnlf
DB_USER=pnlf_app
DB_PASSWORD=4cf231ab03284c8674075b794639cde8d9fe807998f397cb
DB_HOST=pfnl-db
DB_PORT=5432
DB_CONN_MAX_AGE=60
POSTGRES_PASSWORD=a5e722d0fb648e088be164766fbe16480b54b933d9b80d8c

GUNICORN_WORKERS=3
GUNICORN_THREADS=4
GUNICORN_TIMEOUT=60
RUN_MIGRATIONS=true

TUNNEL_TOKEN=COLLER_LE_TOKEN_DU_TUNNEL_ICI

MEDIA_S3_BUCKET=
MEDIA_S3_ENDPOINT_URL=
MEDIA_S3_ACCESS_KEY_ID=
MEDIA_S3_SECRET_ACCESS_KEY=
MEDIA_S3_REGION=auto
MEDIA_S3_PREFIX=media/

NSFW_ACTIF=True
NSFW_SEUIL_DOUTEUX=0.60
NSFW_SEUIL_EXPLICITE=0.92
NSFW_THREADS=1

DJANGO_EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=
EMAIL_PORT=587
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
EMAIL_USE_TLS=True
EMAIL_USE_SSL=False
DEFAULT_FROM_EMAIL=PFNL <no-reply@pnlf.ga>

TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_FROM_NUMBER=
'''.trim() + '\n'

// Attend qu'un conteneur soit "healthy" ; affiche ses logs et échoue sinon.
def waitHealthy(String container, int maxSeconds) {
    sh """
        set +x
        end=\$((\$(date +%s) + ${maxSeconds}))
        while :; do
            s=\$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' ${container} 2>/dev/null || echo absent)
            if [ "\$s" = healthy ]; then echo ">>> ${container} : healthy"; exit 0; fi
            if [ "\$s" = unhealthy ] || [ "\$s" = absent ] || [ \$(date +%s) -ge \$end ]; then
                echo ">>> ${container} non opérationnel (état : \$s)"
                docker logs --tail 120 ${container} 2>&1 || true
                exit 1
            fi
            sleep 3
        done
    """
}

pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    parameters {
        booleanParam(name: 'RESET_DB', defaultValue: false,
            description: 'DANGER : supprime la base PFNL (volume pfnl-db-data) et la recharge depuis backend/db_pfnl.sql')
    }

    environment {
        PFNL_ENV          = '.pfnl-backend.env'                // généré au début du build, supprimé à la fin
        NET               = 'pfnl-net'
        DB_CONTAINER      = 'pfnl-db'
        DB_IMAGE          = 'pfnl-db:18'
        DB_VOLUME         = 'pfnl-db-data'
        BACKEND_IMAGE     = 'pfnl-backend'
        BACKEND_ALIAS     = 'pfnl-backend'                     // nom DNS stable visé par le tunnel
        BACKEND_CONTAINER = "pfnl-backend-${env.BUILD_NUMBER}"
        MEDIA_VOLUME      = 'pfnl-media'
        TUNNEL_CONTAINER  = 'pfnl-tunnel'
        CLOUDFLARED_IMAGE = 'cloudflare/cloudflared:latest'
    }

    stages {

        stage('Vérifications') {
            steps {
                writeFile file: '.pfnl-backend.env', text: PFNL_ENV_CONTENT
                sh '''
                    chmod 600 "$PFNL_ENV"
                    set -eu
                    docker version --format 'Docker {{.Server.Version}}'
                    if grep -q "$(printf '\\r')" "$PFNL_ENV"; then
                        echo "Le fichier d'environnement est au format Windows (CRLF) : convertissez-le en LF"; exit 1
                    fi
                    for v in DJANGO_SECRET_KEY DJANGO_ALLOWED_HOSTS DB_PASSWORD POSTGRES_PASSWORD TUNNEL_TOKEN; do
                        grep -qE "^${v}=.+" "$PFNL_ENV" || { echo "Variable manquante dans PFNL_ENV_CONTENT : $v"; exit 1; }
                    done
                    
                    db_user="$(grep -E '^DB_USER=' "$PFNL_ENV" | tail -n 1 | cut -d= -f2-)"
                    if [ -n "$db_user" ] && [ "$db_user" != "pnlf_app" ]; then
                        echo "DB_USER doit valoir pnlf_app (rôle créé par le dump)"; exit 1
                    fi
                '''
            }
        }

        stage('Build image backend') {
            steps {
                sh '''
                    docker build -f backend/Dockerfile-jenkinsfile \
                        -t "$BACKEND_IMAGE:$BUILD_NUMBER" \
                        -t "$BACKEND_IMAGE:latest" \
                        backend
                '''
            }
        }

        stage('Base de données') {
            steps {
                sh '''
                    set -eu
                    val() { grep -E "^$1=" "$PFNL_ENV" | tail -n 1 | cut -d= -f2-; }

                    docker network inspect "$NET" >/dev/null 2>&1 || docker network create "$NET"

                    if [ "$RESET_DB" = "true" ]; then
                        echo ">>> RESET_DB : suppression du conteneur et du volume de la base PFNL"
                        docker rm -f "$DB_CONTAINER" >/dev/null 2>&1 || true
                        docker volume rm "$DB_VOLUME" >/dev/null 2>&1 || true
                    fi

                    if docker container inspect "$DB_CONTAINER" >/dev/null 2>&1; then
                        echo ">>> $DB_CONTAINER existe déjà : données conservées"
                        docker start "$DB_CONTAINER" >/dev/null
                    else
                        if ! docker volume inspect "$DB_VOLUME" >/dev/null 2>&1; then
                            test -f backend/db_pfnl.sql || { echo "backend/db_pfnl.sql introuvable (requis pour la 1re initialisation)"; exit 1; }
                            echo ">>> Première initialisation : import de backend/db_pfnl.sql"
                            cp backend/db_pfnl.sql backend/deploy/db/10-db_pfnl.sql
                        fi
                        docker build -t "$DB_IMAGE" backend/deploy/db
                        rm -f backend/deploy/db/10-db_pfnl.sql

                        DB_NAME="$(val DB_NAME)"
                        POSTGRES_PASSWORD="$(val POSTGRES_PASSWORD)" \
                        PNLF_APP_PASSWORD="$(val DB_PASSWORD)" \
                        docker run -d --name "$DB_CONTAINER" \
                            --network "$NET" \
                            --restart unless-stopped \
                            -e POSTGRES_PASSWORD \
                            -e PNLF_APP_PASSWORD \
                            -e POSTGRES_DB="${DB_NAME:-pnlf}" \
                            -v "$DB_VOLUME":/var/lib/postgresql \
                            --log-opt max-size=10m --log-opt max-file=3 \
                            "$DB_IMAGE"
                    fi
                '''
                waitHealthy(env.DB_CONTAINER, 300)
            }
        }

        stage('Déploiement backend') {
            steps {
                // Le nouveau conteneur démarre à côté de l'ancien (même alias DNS) :
                // l'ancien n'est supprimé que si le nouveau est sain => pas de coupure, rollback implicite.
                sh '''
                    set -eu
                    docker rm -f "$BACKEND_CONTAINER" >/dev/null 2>&1 || true
                    docker run -d --name "$BACKEND_CONTAINER" \
                        --label pfnl.role=backend \
                        --network "$NET" \
                        --network-alias "$BACKEND_ALIAS" \
                        --restart unless-stopped \
                        --env-file "$PFNL_ENV" \
                        -e DB_HOST="$DB_CONTAINER" \
                        -e DB_PORT=5432 \
                        -e POSTGRES_PASSWORD= \
                        -e TUNNEL_TOKEN= \
                        -v "$MEDIA_VOLUME":/app/media \
                        --log-opt max-size=10m --log-opt max-file=3 \
                        "$BACKEND_IMAGE:$BUILD_NUMBER"
                '''
                script {
                    try {
                        waitHealthy(env.BACKEND_CONTAINER, 240)
                    } catch (err) {
                        // Nouvelle version défaillante : on la retire, l'ancienne continue de servir
                        sh 'docker rm -f "$BACKEND_CONTAINER" >/dev/null 2>&1 || true'
                        throw err
                    }
                }
                sh '''
                    for c in $(docker ps -a --filter label=pfnl.role=backend --format '{{.Names}}'); do
                        if [ "$c" != "$BACKEND_CONTAINER" ]; then
                            echo ">>> Arrêt de l'ancienne version : $c"
                            docker stop -t 30 "$c" >/dev/null && docker rm "$c" >/dev/null
                        fi
                    done
                '''
            }
        }

        stage('Tunnel Cloudflare') {
            steps {
                sh '''
                    set -eu

                    docker rm -f "$TUNNEL_CONTAINER" >/dev/null 2>&1 || true

                    docker run -d \
                        --name "$TUNNEL_CONTAINER" \
                        --network "$NET" \
                        --restart unless-stopped \
                        --log-opt max-size=10m \
                        --log-opt max-file=3 \
                        "$CLOUDFLARED_IMAGE" \
                        tunnel --no-autoupdate \
                        --url http://pfnl-backend:8000

                    echo ">>> Démarrage du Cloudflare Quick Tunnel"

                    for i in $(seq 1 40); do
                        URL=$(docker logs "$TUNNEL_CONTAINER" 2>&1 \
                            | grep -Eo 'https://[a-zA-Z0-9-]+\\.trycloudflare\\.com' \
                            | head -n 1 || true)

                        if [ -n "$URL" ]; then
                            echo ">>> Tunnel disponible : $URL"
                            printf '%s\\n' "$URL" > pfnl-url.txt
                            exit 0
                        fi

                        if [ "$(docker inspect -f '{{.State.Running}}' "$TUNNEL_CONTAINER")" != "true" ]; then
                            docker logs "$TUNNEL_CONTAINER"
                            exit 1
                        fi

                        sleep 3
                    done

                    echo ">>> Impossible de récupérer l'adresse Quick Tunnel"
                    docker logs --tail 100 "$TUNNEL_CONTAINER"
                    exit 1
                '''
            }
        }
    }

    post {
        always {
            sh '''
                rm -f backend/deploy/db/10-db_pfnl.sql "$PFNL_ENV"
                # Garde les 3 dernières images backend numérotées
                docker images "$BACKEND_IMAGE" --format '{{.Tag}}' | grep -E '^[0-9]+$' | sort -rn | tail -n +4 \
                    | while read -r t; do docker rmi "$BACKEND_IMAGE:$t" >/dev/null 2>&1 || true; done
                docker image prune -f >/dev/null 2>&1 || true
            '''
        }
        success {
            echo "PFNL déployé : ${env.BACKEND_IMAGE}:${env.BUILD_NUMBER} (${env.BACKEND_CONTAINER})"
        }
    }
}