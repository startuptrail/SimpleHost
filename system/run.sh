#!/usr/bin/env bash
set -uo pipefail
C=$'\033[1;36m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; W=$'\033[1;37m'; D=$'\033[0;90m'; N=$'\033[0m'
pause() { read -r -p $'\nPress Enter to return...' _ || true; }
while true; do
  clear 2>/dev/null || true
  echo "${C}SIMPLEHOST CLOUD / SYSTEM TOOLS${N}"
  echo "${D}Read-only diagnostics unless an option explicitly says otherwise.${N}"
  echo "────────────────────────────────────────────────────────────"
  echo " [1] Live system summary"
  echo " [2] Disk usage"
  echo " [3] Memory and swap"
  echo " [4] Top CPU processes"
  echo " [5] Listening ports"
  echo " [6] Failed services"
  echo " [7] Recent system errors"
  echo " [0] Back"
  read -r -p 'simplehost / system > ' choice || exit 0
  case "$choice" in
    1) hostnamectl 2>/dev/null || hostname; uptime; free -h; df -hP /; ;;
    2) df -hT; ;;
    3) free -h; ;;
    4) ps aux --sort=-%cpu | head -n 16; ;;
    5) if command -v ss >/dev/null 2>&1; then ss -tulpn; else echo "Install iproute2 to use ss."; fi; ;;
    6) if command -v systemctl >/dev/null 2>&1; then systemctl --failed --no-pager; else echo "systemctl unavailable."; fi; ;;
    7) if command -v journalctl >/dev/null 2>&1; then sudo journalctl -p err -n 60 --no-pager; else echo "journalctl unavailable."; fi; ;;
    0|b|back|exit) exit 0 ;;
    *) echo "${R}Invalid option.${N}" ;;
  esac
  pause
done
