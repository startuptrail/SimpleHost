#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo/root."; exit 1; }
[[ -f /etc/os-release ]] || { echo "Unsupported OS."; exit 1; }
. /etc/os-release
case "${ID:-}" in ubuntu|debian) ;; *) echo "This helper supports Ubuntu/Debian only."; exit 1;; esac
echo "SimpleHost optional XRDP helper"
echo "It installs a remote desktop service. Do not expose TCP/3389 publicly without firewall/VPN controls."
read -r -p 'Install XRDP and XFCE desktop packages? [y/N] ' confirm
[[ "$confirm" == y || "$confirm" == Y ]] || exit 0
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y xrdp xfce4 xfce4-goodies
systemctl enable --now xrdp
echo "Installed. Firewall configuration was not changed. Restrict port 3389 to trusted IPs or a VPN before connecting."
