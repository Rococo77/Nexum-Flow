#!/bin/bash
# ============================================================
# NEXUM FLOW – Script d'import des workflows n8n
# Usage: ./scripts/import-workflows.sh [dossier-optionnel]
# ============================================================

set -e

N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-}"
WORKFLOWS_DIR="${1:-./workflows}"

if [ -z "$N8N_API_KEY" ]; then
  echo "❌ Variable N8N_API_KEY manquante"
  echo "   Exportez-la : export N8N_API_KEY=votre_cle"
  exit 1
fi

echo "🚀 Import des workflows NEXUM FLOW"
echo "   n8n : $N8N_URL"
echo "   Dossier : $WORKFLOWS_DIR"
echo ""

SUCCESS=0
FAIL=0

import_workflow() {
  local file="$1"
  local name
  name=$(python3 -c "import json,sys; d=json.load(open('$file')); print(d.get('name','?'))" 2>/dev/null || echo "$file")

  response=$(curl -s -w "\n%{http_code}" \
    -X POST "$N8N_URL/api/v1/workflows" \
    -H "X-N8N-API-KEY: $N8N_API_KEY" \
    -H "Content-Type: application/json" \
    -d @"$file")

  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | head -n-1)

  if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
    echo "  ✅ $name"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "  ❌ $name (HTTP $http_code)"
    echo "     $body" | head -c 200
    FAIL=$((FAIL + 1))
  fi
}

# Parcourir tous les dossiers de workflows par ordre
for dir in "$WORKFLOWS_DIR"/*/; do
  if [ -d "$dir" ]; then
    section=$(basename "$dir")
    echo "📁 $section"
    for json_file in "$dir"*.json; do
      if [ -f "$json_file" ]; then
        import_workflow "$json_file"
      fi
    done
    echo ""
  fi
done

echo "========================================"
echo "✅ Importés : $SUCCESS | ❌ Échoués : $FAIL"
echo "========================================"
echo ""
echo "🌐 Accédez à n8n : $N8N_URL"
