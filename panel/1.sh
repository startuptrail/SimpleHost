#!/usr/bin/env bash
set -uo pipefail
BASE_URL="${SIMPLEHOST_RUN_BASE:-https://run.simplehost.qzz.io}"
C=$'\033[1;36m'; P=$'\033[1;35m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; W=$'\033[1;37m'; D=$'\033[0;90m'; N=$'\033[0m'
run_module() {
  local rel="$1" tmp url rc
  tmp="$(mktemp)" || return 1
  url="${BASE_URL%/}/$rel"
  if ! curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 600 "$url" -o "$tmp"; then
    echo "${R}Failed to download module: $url${N}"; rm -f "$tmp"; return 1
  fi
  if ! bash -n "$tmp"; then echo "${R}Syntax validation failed; refusing to run module.${N}"; rm -f "$tmp"; return 1; fi
  bash "$tmp"; rc=$?; rm -f "$tmp"; return "$rc"
}
pause() { read -r -p $'\nPress Enter to return...' _ || true; }
while true; do
  clear 2>/dev/null || true
  echo "${C}┌──────────────────────────────────────────────────────────────┐${N}"
  echo "${C}│${N}  ${W}SIMPLEHOST CLOUD  /  PANEL DEPLOYMENTS${N}                    ${C}│${N}"
  echo "${C}└──────────────────────────────────────────────────────────────┘${N}"
  echo "${D}These modules can modify packages, databases, NGINX and panel files.${N}"
  echo
  echo " ${G}[1]${N} Pterodactyl Panel — install / management"
  echo " ${G}[2]${N} Reviactyl panel manager"
  echo " ${G}[3]${N} Paymenter panel manager"
  echo " ${G}[4]${N} MythicalDash panel manager"
  echo " ${G}[5]${N} PteroCA installer"
  echo " ${G}[6]${N} Convoy installer"
  echo " ${Y}[7]${N} Set up SSL for an existing NGINX site"
  echo " ${R}[0]${N} Back"
  echo
  read -r -p 'simplehost / panel > ' choice || exit 0
  case "$choice" in
    1) run_module 'panel/pterodactyl/run.sh'; pause ;;
    2) run_module 'panel/reviactyl/run.sh'; pause ;;
    3) run_module 'panel/paymenter/run.sh'; pause ;;
    4) run_module 'panel/mythical/run.sh'; pause ;;
    5) run_module 'panel/pteroca/run.sh'; pause ;;
    6) run_module 'panel/Convoy/run.sh'; pause ;;
    7) run_module 'toolbox/ssl.sh'; pause ;;
    0|b|back|exit) exit 0 ;;
    *) echo "${R}Invalid option.${N}"; sleep 1 ;;
  esac
done
