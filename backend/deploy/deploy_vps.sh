#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -f "$BACKEND_DIR/.env.production" ]]; then
  echo ".env.production is missing. Copy .env.production.example and fill in real values first."
  exit 1
fi

cd "$BACKEND_DIR"
docker compose -f docker-compose.prod.yml up -d --build

echo "Deployment complete."
echo "Health check: curl http://127.0.0.1:5000/api/health"
