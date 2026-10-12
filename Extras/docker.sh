#!/usr/bin/env bash
set -uo pipefail
C=$'\033[1;36m'; G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; N=$'\033[0m'
need_docker() { command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; }
pause() { read -r -p $'\nPress Enter to continue...' _ || true; }
if ! need_docker; then echo "Docker is missing or the daemon is unavailable. Install/start Docker first."; exit 1; fi
valid_name() { [[ "$1" =~ ^[a-zA-Z][a-zA-Z0-9_.-]{0,39}$ ]]; }
while true; do
  clear 2>/dev/null || true
  echo "${C}SIMPLEHOST CLOUD / DOCKER CONTAINER MANAGER${N}"
  echo "────────────────────────────────────────────────────────────"
  echo " [1] Create a persistent OS container"
  echo " [2] List containers"
  echo " [3] Start container"
  echo " [4] Stop container"
  echo " [5] Open shell in container"
  echo " [6] View recent logs"
  echo " [7] Remove container (destructive)"
  echo " [8] Docker resource usage"
  echo " [0] Back"
  read -r -p 'simplehost / docker > ' choice || exit 0
  case "$choice" in
    1)
      echo "Available official base images: ubuntu:22.04, ubuntu:24.04, debian:12, debian:13"
      read -r -p 'Container name (starts with letter): ' name
      if ! valid_name "$name"; then echo "Invalid container name."; pause; continue; fi
      if docker container inspect "$name" >/dev/null 2>&1; then echo "That container name already exists."; pause; continue; fi
      read -r -p 'Base image [ubuntu:24.04]: ' image; image=${image:-ubuntu:24.04}
      case "$image" in ubuntu:22.04|ubuntu:24.04|debian:12|debian:13) ;; *) echo "Image not in the allow-list."; pause; continue ;; esac
      read -r -p 'Memory limit [2g]: ' memory; memory=${memory:-2g}
      [[ "$memory" =~ ^[1-9][0-9]*(m|g)$ ]] || { echo "Use a memory limit such as 512m or 2g."; pause; continue; }
      read -r -p 'CPU limit [1]: ' cpus; cpus=${cpus:-1}
      [[ "$cpus" =~ ^[1-9][0-9]*(\.[0-9]+)?$|^0\.[1-9][0-9]*$ ]] || { echo "Invalid CPU limit."; pause; continue; }
      echo "This creates a normal container, not a full virtual machine: no systemd, no privileged mode and no public ports." 
      read -r -p "Create '$name' from '$image' with memory=$memory CPU=$cpus? [y/N] " yes
      if [[ "$yes" == y || "$yes" == Y ]]; then
        docker pull "$image" && docker run -d --name "$name" --restart unless-stopped --memory "$memory" --cpus "$cpus" --pids-limit 512 "$image" sleep infinity
      else echo "Cancelled."; fi
      pause ;;
    2) docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'; pause ;;
    3) read -r -p 'Container name: ' name; if valid_name "$name"; then docker start "$name"; else echo "Invalid name."; fi; pause ;;
    4) read -r -p 'Container name: ' name; if valid_name "$name"; then docker stop "$name"; else echo "Invalid name."; fi; pause ;;
    5)
      read -r -p 'Container name: ' name
      if valid_name "$name" && docker container inspect "$name" >/dev/null 2>&1; then
        docker exec -it "$name" sh || true
      else echo "Container not found or invalid name."; fi
      pause ;;
    6) read -r -p 'Container name: ' name; if valid_name "$name"; then docker logs --tail 100 "$name"; else echo "Invalid name."; fi; pause ;;
    7)
      read -r -p 'Container name to remove: ' name
      if valid_name "$name" && docker container inspect "$name" >/dev/null 2>&1; then
        echo "${Y}This removes the container and its writable layer. Named volumes are not deleted automatically.${N}"
        read -r -p "Type DELETE $name to confirm: " confirm
        if [[ "$confirm" == "DELETE $name" ]]; then docker rm -f "$name"; else echo "Cancelled."; fi
      else echo "Container not found or invalid name."; fi
      pause ;;
    8) docker stats --no-stream; docker system df; pause ;;
    0|b|back|exit) exit 0 ;;
    *) echo "${R}Invalid option.${N}"; sleep 1 ;;
  esac
done
