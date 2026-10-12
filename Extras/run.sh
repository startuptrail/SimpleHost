#!/usr/bin/env bash
set -uo pipefail
BASE_URL="${SIMPLEHOST_RUN_BASE:-https://run.simplehost.qzz.io}"
C=$'\033[1;36m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; N=$'\033[0m'
run_module() {
  local rel="$1" tmp url rc
  tmp="$(mktemp)" || return 1; url="${BASE_URL%/}/$rel"
  if ! curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 600 "$url" -o "$tmp"; then echo "Download failed: $url"; rm -f "$tmp"; return 1; fi
  if ! bash -n "$tmp"; then echo "Syntax check failed; module blocked."; rm -f "$tmp"; return 1; fi
  bash "$tmp"; rc=$?; rm -f "$tmp"; return "$rc"
}
pause() { read -r -p $'\nPress Enter to continue...' _ || true; }
while true; do
  clear 2>/dev/null || true
  echo "${C}SIMPLEHOST CLOUD / INFRASTRUCTURE${N}"
  echo "────────────────────────────────────────────────────"
  echo " [1] Cockpit server console"
  echo " [2] CasaOS"
  echo " [3] 1Panel"
  echo " [4] Docker engine / management"
  echo " [5] LVM / storage manager (legacy, review first)"
  echo " [0] Back"
  echo
  read -r -p 'simplehost / extras > ' choice || exit 0
  case "$choice" in
    1) run_module 'Extras/Cockpit.sh'; pause ;;
    2) run_module 'Extras/casaos.sh'; pause ;;
    3) run_module 'Extras/cpanel.sh'; pause ;;
    4) run_module 'Extras/docker.sh'; pause ;;
    5) echo "${Y}Legacy storage module can download a large unverified binary. It is intentionally not auto-launched from this menu.${N}"; echo "Review Extras/lvm.sh and its download source manually before use."; pause ;;
    0|b|back|exit) exit 0 ;;
    *) echo "${R}Invalid option.${N}"; sleep 1 ;;
  esac
done
