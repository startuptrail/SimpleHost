#!/usr/bin/env bash
set -euo pipefail
BASE_URL="${SIMPLEHOST_RUN_BASE:-https://run.simplehost.qzz.io}"
URL="${BASE_URL%/}/panel/pteroca/install.sh"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
if ! curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 600 "$URL" -o "$TMP"; then
  echo "Download failed: $URL" >&2; exit 1
fi
if ! bash -n "$TMP"; then echo "PteroCA installer failed its Bash syntax check." >&2; exit 1; fi
echo "Starting PteroCA installer from $URL"
bash "$TMP"
