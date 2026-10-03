# Contexte Docker = racine du dépôt GitHub
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Modèle IA de modération des images (URL figée + empreinte SHA-256 vérifiée), couche mise en cache.
# Non bloquant : sans modèle, les images envoyées passent toutes en vérification administrateur.
COPY backend/scripts/telecharger_modele_nsfw.py scripts/
RUN python scripts/telecharger_modele_nsfw.py || echo "WARN: modele NSFW non installe, moderation en mode verification"

COPY backend/ .

RUN chmod +x entrypoint.sh

EXPOSE 8000

CMD ["sh", "entrypoint.sh"]
