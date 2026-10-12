#!/usr/bin/env bash
set -uo pipefail
C=$'\033[1;36m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; N=$'\033[0m'
pause() { read -r -p $'\nPress Enter to continue...' _ || true; }
if ! command -v incus >/dev/null 2>&1; then
  clear 2>/dev/null || true
  echo "${C}SIMPLEHOST CLOUD / NON-KVM CONTAINERS${N}"
  echo "Incus is not installed. This module will not silently alter APT/Snap repositories."
  echo "Install and initialize Incus using your OS's official instructions, then return here."
  echo "Documentation: https://linuxcontainers.org/incus/docs/main/"
  pause; exit 0
fi
while true; do
  clear 2>/dev/null || true
  echo "${C}SIMPLEHOST CLOUD / INCUS CONTAINER MANAGER${N}"
  echo "────────────────────────────────────────────────────"
  echo " [1] List instances"; echo " [2] List images"; echo " [3] Launch Ubuntu 24.04 container"; echo " [4] Start instance"; echo " [5] Stop instance"; echo " [6] Delete instance (destructive)"; echo " [0] Back"
  read -r -p 'simplehost / incus > ' choice || exit 0
  case "$choice" in
    1) incus list; pause ;;
    2) incus image list; pause ;;
    3)
      read -r -p 'Instance name (letters, digits, hyphen; starts with a letter): ' name
      if [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9-]{0,30}$ ]]; then
        read -r -p "Launch Ubuntu 24.04 instance '$name'? [y/N] " ans
        if [[ "$ans" == y || "$ans" == Y ]]; then incus launch images:ubuntu/24.04 "$name"; fi
      else echo "Invalid name."; fi
      pause ;;
    4)
      read -r -p 'Instance name: ' name
      if [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9-]{0,30}$ ]]; then incus start "$name"; else echo "Invalid name."; fi
      pause ;;
    5)
      read -r -p 'Instance name: ' name
      if [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9-]{0,30}$ ]]; then incus stop "$name"; else echo "Invalid name."; fi
      pause ;;
    6)
      read -r -p 'Instance name: ' name
      if [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9-]{0,30}$ ]]; then
        echo "${Y}This permanently deletes the selected container and its writable data.${N}"
        read -r -p "Type DELETE $name to confirm: " ans
        if [[ "$ans" == "DELETE $name" ]]; then incus delete --force "$name"; else echo "Cancelled."; fi
      else echo "Invalid name."; fi
      pause ;;
    0|b|back|exit) exit 0 ;;
    *) echo "${R}Invalid option.${N}"; sleep 1 ;;
  esac
done
