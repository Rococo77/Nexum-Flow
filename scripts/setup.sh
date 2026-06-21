#!/bin/bash
# ============================================================
# NEXUM FLOW – Script de démarrage complet
# Usage: ./scripts/setup.sh
# ============================================================

set -e

DOCKER_DIR="$(dirname "$0")/../docker"

echo "======================================"
echo "  NEXUM FLOW – Setup de l'infrastructure"
echo "======================================"
echo ""

# Vérifier les prérequis
command -v docker >/dev/null 2>&1 || { echo "❌ Docker requis"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ docker-compose requis"; exit 1; }

# Créer le fichier .env s'il n'existe pas
if [ ! -f "$DOCKER_DIR/.env" ]; then
  echo "📝 Création du fichier .env depuis l'exemple..."
  cp "$DOCKER_DIR/.env.example" "$DOCKER_DIR/.env"
  echo "⚠️  IMPORTANT: Éditez $DOCKER_DIR/.env avec vos valeurs avant de continuer"
  echo "   nano $DOCKER_DIR/.env"
  echo ""
  read -p "Appuyez sur Entrée quand le .env est configuré..."
fi

# Créer le fichier acme.json pour Traefik (permissions strictes)
touch "$DOCKER_DIR/traefik/acme.json"
chmod 600 "$DOCKER_DIR/traefik/acme.json"

# Créer le fichier htpasswd pour le dashboard Traefik et MinIO
if [ ! -f "$DOCKER_DIR/traefik/users.htpasswd" ]; then
  if command -v htpasswd >/dev/null 2>&1; then
    echo ""
    echo "🔐 Création des identifiants du dashboard Traefik..."
    read -rp "   Nom d'utilisateur dashboard : " DASH_USER
    htpasswd -c "$DOCKER_DIR/traefik/users.htpasswd" "$DASH_USER"
    echo "✅ Fichier htpasswd créé"
  else
    echo "⚠️  htpasswd non disponible. Installez apache2-utils puis lancez :"
    echo "   htpasswd -c $DOCKER_DIR/traefik/users.htpasswd admin"
    touch "$DOCKER_DIR/traefik/users.htpasswd"
  fi
fi

# Démarrer les services
echo ""
echo "🐳 Démarrage des services Docker..."
cd "$DOCKER_DIR"
docker-compose pull
docker-compose up -d

echo ""
echo "⏳ Attente que les services soient prêts..."
sleep 15

# Vérifier les services
echo ""
echo "🔍 Statut des services :"
docker-compose ps

echo ""
echo "======================================"
echo "✅ Infrastructure démarrée !"
echo ""
echo "📎 Accès :"
source .env 2>/dev/null || true
echo "   n8n    : https://${N8N_HOST:-localhost:5678}"
echo "   MinIO  : https://${MINIO_HOST:-localhost:9001}"
echo "   API    : https://${API_HOST:-localhost:8000}"
echo ""
echo "📦 Import des workflows :"
echo "   export N8N_API_KEY=votre_cle"
echo "   ./scripts/import-workflows.sh"
echo "======================================"
