#!/usr/bin/env bash
# SimpleHost Cloud — restricted MariaDB database/user setup
set -Eeuo pipefail

C=$'\033[1;36m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; N=$'\033[0m'

if (( EUID != 0 )); then
  echo "Run as root: sudo bash $0"
  exit 1
fi
if [[ -r /etc/os-release ]]; then . /etc/os-release; fi
case "${ID:-}" in ubuntu|debian) ;; *) echo "Supported on Ubuntu/Debian only."; exit 1 ;; esac

clear 2>/dev/null || true
echo "${C}SIMPLEHOST CLOUD / DATABASE ACCESS SETUP${N}"
echo "────────────────────────────────────────────────────────────"
echo "Safer defaults: database-scoped grants, no GRANT OPTION, no public-wide firewall rule."

if ! command -v mariadb >/dev/null 2>&1 && ! command -v mysql >/dev/null 2>&1; then
  read -r -p "MariaDB isn't installed. Install it now? [y/N] " install_db
  [[ "$install_db" == y || "$install_db" == Y ]] || exit 1
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client
  systemctl enable --now mariadb
fi

sql=(mariadb)
command -v mariadb >/dev/null 2>&1 || sql=(mysql)
if ! "${sql[@]}" -Nse 'SELECT 1' >/dev/null 2>&1; then
  echo "Cannot connect through local database socket as root. Configure MariaDB root access first."
  exit 1
fi

read -r -p "Database name [pterodactyl]: " DB_NAME; DB_NAME=${DB_NAME:-pterodactyl}
read -r -p "Database username [simplehost_app]: " DB_USER; DB_USER=${DB_USER:-simplehost_app}
read -r -p "Allowed client IP [127.0.0.1; remote client IP for remote access]: " SOURCE_IP; SOURCE_IP=${SOURCE_IP:-127.0.0.1}
[[ "$DB_NAME" =~ ^[A-Za-z0-9_]{1,64}$ ]] || { echo "Invalid database name."; exit 1; }
[[ "$DB_USER" =~ ^[A-Za-z0-9_]{1,32}$ ]] || { echo "Invalid database username."; exit 1; }

# Validate IPv4 input without depending on ipcalc.
if [[ ! "$SOURCE_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  echo "Enter a single IPv4 address (no 0.0.0.0 or wildcard)."; exit 1
fi
IFS=. read -r o1 o2 o3 o4 <<< "$SOURCE_IP"
for octet in "$o1" "$o2" "$o3" "$o4"; do
  (( 10#$octet <= 255 )) || { echo "Invalid IPv4 octet."; exit 1; }
done
[[ "$SOURCE_IP" != "0.0.0.0" ]] || { echo "Wildcard source addresses are blocked."; exit 1; }

DB_PASS="$(openssl rand -hex 24)"
if [[ "$SOURCE_IP" != "127.0.0.1" ]]; then
  echo "${Y}Remote access requested from $SOURCE_IP. This changes MariaDB to listen on network interfaces.${N}"
  echo "Firewall access will be limited to the client IP you entered. Check your cloud firewall too."
  read -r -p "Type ENABLE RESTRICTED REMOTE DB to continue: " remote_confirm
  [[ "$remote_confirm" == "ENABLE RESTRICTED REMOTE DB" ]] || { echo "Cancelled."; exit 1; }
fi

printf '\nDatabase: %s\nUser: %s\nAllowed source: %s\n' "$DB_NAME" "$DB_USER" "$SOURCE_IP"
read -r -p "Create database/user and grant access? [y/N] " confirm
[[ "$confirm" == y || "$confirm" == Y ]] || { echo "Cancelled."; exit 0; }

"${sql[@]}" <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'$SOURCE_IP' IDENTIFIED BY '$DB_PASS';
ALTER USER '$DB_USER'@'$SOURCE_IP' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'$SOURCE_IP';
FLUSH PRIVILEGES;
SQL

if [[ "$SOURCE_IP" != "127.0.0.1" ]]; then
  conf="/etc/mysql/mariadb.conf.d/50-server.cnf"
  if [[ -f "$conf" ]]; then
    cp -a "$conf" "$conf.simplehost-backup.$(date +%Y%m%d-%H%M%S)"
    if grep -Eq '^[[:space:]]*bind-address[[:space:]]*=' "$conf"; then
      sed -i -E 's/^[[:space:]]*bind-address[[:space:]]*=.*/bind-address = 0.0.0.0/' "$conf"
    else
      sed -i '/^\[mysqld\]/a bind-address = 0.0.0.0' "$conf"
    fi
  else
    echo "Could not find MariaDB server config; review bind-address manually."
  fi
  systemctl restart mariadb
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi active; then
    ufw allow from "$SOURCE_IP" to any port 3306 proto tcp
  fi
fi

CREDENTIALS_FILE="/root/simplehost-db-credentials.txt"
printf 'Database: %s\nUsername: %s\nPassword: %s\nAllowed source IP: %s\n' "$DB_NAME" "$DB_USER" "$DB_PASS" "$SOURCE_IP" > "$CREDENTIALS_FILE"
chmod 600 "$CREDENTIALS_FILE"
echo "${G}Database access configured.${N}"
echo "Credentials saved to $CREDENTIALS_FILE (permissions 600)."
echo "Never expose TCP/3306 publicly; add matching allow rules in your VPS provider firewall."
