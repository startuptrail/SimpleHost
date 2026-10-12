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
  echo "${C}SIMPLEHOST CLOUD / TOOLBOX${N}"; echo "────────────────────────────────────────────────────────"
  echo " [1] Root / SSH helpers"; echo " [2] Tailscale VPN"; echo " [3] ZeroTier VPN"; echo " [4] Cloudflare Tunnel"; echo " [5] System information and utilities"; echo " [6] Localtonet tunnel"; echo " [7] Terminal access helpers"; echo " [8] XRDP remote desktop (review firewall first)"; echo " [9] SSL certificate helper"; echo " [0] Back"
  read -r -p 'simplehost / tools > ' choice || exit 0
  case "$choice" in
    1) run_module 'toolbox/root.sh'; pause ;;
    2) run_module 'toolbox/tailscale.sh'; pause ;;
    3) run_module 'toolbox/zerotier.sh'; pause ;;
    4) run_module 'toolbox/cloudflare.sh'; pause ;;
    5) run_module 'toolbox/info.sh'; pause ;;
    6) run_module 'toolbox/localtonet.sh'; pause ;;
    7) run_module 'toolbox/terminal.sh'; pause ;;
    8) run_module 'toolbox/rdp.sh'; pause ;;
    9) run_module 'toolbox/ssl.sh'; pause ;;
    0|b|back|exit) exit 0 ;;
    *) echo "${R}Invalid selection.${N}"; sleep 1 ;;
  esac
done
