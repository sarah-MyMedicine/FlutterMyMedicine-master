#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash deploy/install_nginx_site.sh api.yourdomain.com"
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <api-domain>"
  exit 1
fi

DOMAIN="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="$SCRIPT_DIR/nginx.mymedicine.conf"
TARGET_PATH="/etc/nginx/sites-available/mymedicine-backend"

if [[ ! -f "$TEMPLATE_PATH" ]]; then
  echo "Template not found at $TEMPLATE_PATH"
  exit 1
fi

sed "s/api\.example\.com/${DOMAIN//\//\\/}/g" "$TEMPLATE_PATH" > "$TARGET_PATH"
ln -sf "$TARGET_PATH" /etc/nginx/sites-enabled/mymedicine-backend
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "Nginx site installed for $DOMAIN"
echo "Next step: certbot --nginx -d $DOMAIN"
