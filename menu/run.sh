#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P || true)"
if [[ -f "$HERE/UI.sh" ]]; then exec bash "$HERE/UI.sh" "$@"; fi
BASE_URL="${SIMPLEHOST_RUN_BASE:-https://run.simplehost.qzz.io}"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 60 "${BASE_URL%/}/install.sh" -o "$TMP"
bash -n "$TMP"
bash "$TMP" "$@"
