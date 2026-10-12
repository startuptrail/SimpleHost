#!/usr/bin/env bash
set -euo pipefail
C=$'\033[1;36m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; N=$'\033[0m'
[[ $EUID -eq 0 ]] || { echo "Run with sudo/root."; exit 1; }
command -v certbot >/dev/null 2>&1 || { echo "Install certbot and the NGINX plugin first: apt install certbot python3-certbot-nginx"; exit 1; }
command -v nginx >/dev/null 2>&1 || { echo "NGINX is not installed."; exit 1; }
read -r -p 'Domain (example: ptero.simplehost.qzz.io): ' DOMAIN
read -r -p 'Email for certificate notices: ' EMAIL
[[ "$DOMAIN" =~ ^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] || { echo "Invalid domain."; exit 1; }
[[ "$EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]] || { echo "Invalid email."; exit 1; }
echo "\n${Y}Before proceeding, ensure this domain resolves to this server and ports 80/443 are reachable.${N}"
read -r -p 'Request/renew certificate using Certbot NGINX plugin? [y/N] ' answer
[[ "$answer" == y || "$answer" == Y ]] || { echo "Cancelled; existing certificates were not changed."; exit 0; }
nginx -t
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
systemctl reload nginx
echo "${G}Certbot completed. Review its output for the final certificate status.${N}"
