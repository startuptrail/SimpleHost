#!/usr/bin/env bash
# Compatibility alias for the maintained SimpleHost Pterodactyl manager.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/run.sh" "$@"
