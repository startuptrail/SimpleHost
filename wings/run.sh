#!/usr/bin/env bash
set -uo pipefail
BASE_URL="${SIMPLEHOST_RUN_BASE:-https://run.simplehost.qzz.io}"
C=$'\033[1;36m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; W=$'\033[1;37m'; D=$'\033[0;90m'; N=$'\033[0m'
run_module() {
  local rel="$1" tmp url rc
  tmp="$(mktemp)" || return 1; url="${BASE_URL%/}/$rel"
  if ! curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 600 "$url" -o "$tmp"; then echo "Download failed: $url"; rm -f "$tmp"; return 1; fi
  if ! bash -n "$tmp"; then echo "Syntax check failed; refusing to run this module."; rm -f "$tmp"; return 1; fi
  bash "$tmp"; rc=$?; rm -f "$tmp"; return "$rc"
}
pause() { read -r -p $'\nPress Enter to return...' _ || true; }
while true; do
  clear 2>/dev/null || true
  echo "${C}┌──────────────────────────────────────────────────────────────┐${N}"
  echo "${C}│${N}  ${W}SIMPLEHOST CLOUD  /  WINGS CONTROL${N}                        ${C}│${N}"
  echo "${C}└──────────────────────────────────────────────────────────────┘${N}"
  if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet wings; then echo "Wings status: ${G}ACTIVE${N}"; else echo "Wings status: ${Y}inactive / not installed${N}"; fi
  echo; echo " [1] Install Wings"; echo " [2] Wings configuration manager"; echo " [3] Database helper"; echo " [4] Configure SSL for a domain"; echo " [5] View Wings logs"; echo " [6] Restart Wings (confirmation required)"; echo " [7] Uninstall Wings binary/service only (keeps server data)"; echo " [0] Back"
  read -r -p 'simplehost / wings > ' choice || exit 0
  case "$choice" in
    1) run_module 'wings/install.sh'; pause ;;
    2) run_module 'wings/mang.sh'; pause ;;
    3) run_module 'wings/db.sh'; pause ;;
    4) run_module 'toolbox/ssl.sh'; pause ;;
    5) if command -v journalctl >/dev/null 2>&1; then sudo journalctl -u wings -n 100 --no-pager; else echo "journalctl unavailable"; fi; pause ;;
    6) read -r -p 'Restart Wings now? Game servers may be interrupted. [y/N] ' answer; if [[ "$answer" == y || "$answer" == Y ]]; then sudo systemctl restart wings && echo "Wings restart requested."; fi; pause ;;
    7)
      echo "${Y}This removes the Wings service/binary but preserves /etc/pterodactyl and /var/lib/pterodactyl.${N}"
      read -r -p 'Type REMOVE WINGS to continue: ' answer
      if [[ "$answer" == 'REMOVE WINGS' ]]; then
        sudo systemctl disable --now wings 2>/dev/null || true
        sudo rm -f /etc/systemd/system/wings.service /usr/local/bin/wings
        sudo systemctl daemon-reload
        echo "Service/binary removed. Docker and server data were not pruned or deleted."
      else echo "Cancelled."; fi
      pause ;;
    0|b|back|exit) exit 0 ;;
    *) echo "${R}Invalid selection.${N}"; sleep 1 ;;
  esac
done
