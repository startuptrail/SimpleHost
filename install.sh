#!/usr/bin/env bash
# SimpleHost Cloud Control Center — menu v2.0
set -uo pipefail

APP_NAME="SIMPLEHOST CLOUD"
VERSION="2.0.0"
BASE_URL="${SIMPLEHOST_RUN_BASE:-https://run.simplehost.qzz.io}"

# Palette chosen for readability, not terminal-font-dependent icons.
C=$'\033[1;36m'; B=$'\033[1;34m'; G=$'\033[1;32m'; Y=$'\033[1;33m'
R=$'\033[1;31m'; W=$'\033[1;37m'; D=$'\033[0;90m'; P=$'\033[1;35m'; N=$'\033[0m'

PROJECT_ROOT=""
script_path="${BASH_SOURCE[0]:-}"
if [[ -n "$script_path" && -f "$script_path" ]]; then
    script_dir="$(cd -- "$(dirname -- "$script_path")" 2>/dev/null && pwd -P)" || script_dir=""
    if [[ -d "${script_dir}/panel" && -d "${script_dir}/wings" ]]; then
        PROJECT_ROOT="$script_dir"
    elif [[ -d "${script_dir}/../panel" && -d "${script_dir}/../wings" ]]; then
        PROJECT_ROOT="$(cd -- "${script_dir}/.." && pwd -P)"
    fi
fi

line() { printf '%s\n' "${D}──────────────────────────────────────────────────────────────────────${N}"; }
pause() { read -r -p $'\nPress Enter to return...' _ || true; }

get_cpu() {
    local u n s idle wa irq sirq steal total1 idle1 total2 idle2
    read -r _ u n s idle wa irq sirq steal _ < /proc/stat 2>/dev/null || { printf 'N/A'; return; }
    total1=$((u+n+s+idle+wa+irq+sirq+steal)); idle1=$((idle+wa))
    sleep 0.12
    read -r _ u n s idle wa irq sirq steal _ < /proc/stat 2>/dev/null || { printf 'N/A'; return; }
    total2=$((u+n+s+idle+wa+irq+sirq+steal)); idle2=$((idle+wa))
    local dt=$((total2-total1)) di=$((idle2-idle1))
    (( dt > 0 )) && printf '%s%%' "$(((dt-di)*100/dt))" || printf 'N/A'
}
get_metrics() {
    HOST="$(hostname 2>/dev/null || printf unknown)"
    OS="$(. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-Linux}")"
    UPTIME="$(uptime -p 2>/dev/null | sed 's/^up //' || printf unknown)"
    CPU="$(get_cpu)"
    RAM="$(free -b 2>/dev/null | awk '/^Mem:/ { if ($2>0) printf "%.0f%%",100*$3/$2 }' 2>/dev/null)"
    RAM_DETAIL="$(free -h 2>/dev/null | awk '/^Mem:/ {printf "%s / %s",$3,$2}' 2>/dev/null || true)"
    [[ -n "$RAM" ]] || RAM="N/A"
    [[ -n "${RAM_DETAIL:-}" ]] && RAM="$RAM ($RAM_DETAIL)"
    DISK="$(df -hP / 2>/dev/null | awk 'NR==2 {printf "%s used of %s (%s)",$3,$2,$5}' || printf N/A)"
    IPS="$(hostname -I 2>/dev/null | awk '{$1=$1; print}' || printf N/A)"
}

run_module() {
    local rel="$1" encoded tmp url local_path
    local_path="${rel//%20/ }"
    if [[ -n "$PROJECT_ROOT" && -f "$PROJECT_ROOT/$local_path" ]]; then
        echo "${C}Launching local module:${N} $rel"
        bash "$PROJECT_ROOT/$local_path"
        return $?
    fi
    encoded="$rel"
    url="${BASE_URL%/}/$encoded"
    tmp="$(mktemp)" || { echo "${R}Could not create temporary file.${N}"; return 1; }
    if ! curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
        --connect-timeout 10 --max-time 600 "$url" -o "$tmp"; then
        echo "${R}Download failed:${N} $url"; rm -f "$tmp"; return 1
    fi
    if ! bash -n "$tmp"; then
        echo "${R}Downloaded module failed its Bash syntax check; refusing to run it.${N}"
        rm -f "$tmp"; return 1
    fi
    echo "${Y}Downloaded:${N} $url"
    echo "${D}Syntax check passed. Remote shell modules still require trust in your host.${N}"
    bash "$tmp"
    local rc=$?
    rm -f "$tmp"
    return "$rc"
}

render() {
    clear 2>/dev/null || true
    get_metrics
    printf '\n%s' "$C"
    cat <<'LOGO'
  ____  ___ __  __ ____  _     _____ _   _  ___  ____ _____
 / ___|/ _ \  \/  |  _ \| |   | ____| \ | |/ _ \/ ___|_   _|
 \___ \ | | | |\/| | |_) | |   |  _| |  \| | | | \___ \ | |
  ___) | |_| | |  | |  __/| |___| |___| |\  | |_| |___) || |
 |____/ \___/|_|  |_|_|   |_____|_____|_| \_|\___/|____/ |_|
LOGO
    printf '%s\n' "$N"
    printf ' %sCLOUD CONTROL CENTER%s  %sv%s%s\n' "$W" "$N" "$D" "$VERSION" "$N"
    line
    printf ' %sHOST%s %-24s %sOS%s %s\n' "$C" "$N" "$HOST" "$C" "$N" "$OS"
    printf ' %sUPTIME%s %-22s %sCPU%s %-8s %sRAM%s %s\n' "$C" "$N" "$UPTIME" "$C" "$N" "$CPU" "$C" "$N" "$RAM"
    printf ' %sROOT DISK%s %s\n' "$C" "$N" "$DISK"
    printf ' %sLOCAL IP%s %s\n' "$C" "$N" "${IPS:-N/A}"
    line
    printf '\n %sDEPLOYMENT%s\n' "$P" "$N"
    printf '  %s[1]%s Virtual machines / QEMU\n' "$G" "$N"
    printf '  %s[2]%s Panel installers and managers\n' "$G" "$N"
    printf '  %s[3]%s Wings daemon manager\n' "$G" "$N"
    printf '  %s[4]%s Network and server toolbox\n' "$G" "$N"
    printf '\n %sOPERATIONS%s\n' "$P" "$N"
    printf '  %s[5]%s Panel themes and Blueprint extensions\n' "$B" "$N"
    printf '  %s[6]%s System diagnostics and maintenance\n' "$B" "$N"
    printf '  %s[7]%s Incus containers / non-KVM manager\n' "$B" "$N"
    printf '  %s[8]%s Infrastructure add-ons\n' "$B" "$N"
    printf '  %s[9]%s Pterodactyl health check\n' "$B" "$N"
    printf '  %s[10]%s About, domains and safety notes\n' "$B" "$N"
    printf '  %s[0]%s Exit\n' "$R" "$N"
    line
}

health_check() {
    clear
    echo "${C}PTERODACTYL HEALTH CHECK${N}"; line
    for service in nginx mariadb mysql redis-server pteroq wings; do
        if command -v systemctl >/dev/null 2>&1; then
            if systemctl is-active --quiet "$service"; then printf ' %-18s %sACTIVE%s\n' "$service" "$G" "$N"
            else printf ' %-18s %sINACTIVE / ABSENT%s\n' "$service" "$Y" "$N"; fi
        fi
    done
    for p in /var/www/pterodactyl /etc/pterodactyl /var/lib/pterodactyl; do
        [[ -e "$p" ]] && printf ' %-18s %sPRESENT%s\n' "$p" "$G" "$N" || printf ' %-18s %sNOT FOUND%s\n' "$p" "$D" "$N"
    done
    pause
}

about() {
    clear
    echo "${C}SIMPLEHOST CLOUD — ABOUT${N}"; line
    echo " Installer host : ${BASE_URL}"
    echo " Panel example  : https://ptero.simplehost.qzz.io"
    echo " Local mode     : ${PROJECT_ROOT:-not detected (remote mode)}"
    echo
    echo "The ptero hostname is only a suggested domain. DNS must point to the"
    echo "correct server, and the installer will still ask you to confirm it."
    echo
    echo "Security: modules may change system files and install services. Review"
    echo "the script and keep backups. This launcher downloads a module to a temp"
    echo "file and checks syntax; that is not a security audit or signature check."
    pause
}

while true; do
    render
    read -r -p 'simplehost > ' choice || exit 0
    case "$choice" in
        1) run_module 'setup%20vm/menu.sh'; pause ;;
        2) run_module 'panel/1.sh'; pause ;;
        3) run_module 'wings/run.sh'; pause ;;
        4) run_module 'toolbox/run.sh'; pause ;;
        5) run_module 'thame/run.sh'; pause ;;
        6) run_module 'system/run.sh'; pause ;;
        7) run_module 'setup%20vm/no-kvm.sh'; pause ;;
        8) run_module 'Extras/run.sh'; pause ;;
        9) health_check ;;
        10) about ;;
        0|q|quit|exit) echo "${G}SimpleHost session closed.${N}"; exit 0 ;;
        *) echo "${R}Invalid selection.${N}"; sleep 1 ;;
    esac
done
