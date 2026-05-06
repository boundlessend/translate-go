#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DMG_PATH="$("${ROOT_DIR}/scripts/build_dmg.sh")"

echo "DMG: ${DMG_PATH}"
