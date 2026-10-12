#!/usr/bin/env bash
# Compatibility alias: use the maintained SimpleHost theme/Blueprint menu.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/run.sh" "$@"
