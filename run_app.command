#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$("${ROOT_DIR}/scripts/build_app.sh")"
if [[ -w "/Applications" ]]; then
  INSTALL_DIR="/Applications"
else
  INSTALL_DIR="${HOME}/Applications"
fi
INSTALLED_APP_DIR="${INSTALL_DIR}/translate&go.app"
OLD_APP_DIR="${INSTALL_DIR}/OllamaTranslatorApp.app"

/usr/bin/pkill -x "OllamaTranslatorApp" 2>/dev/null || true
/usr/bin/pkill -x "translate&go" 2>/dev/null || true
/bin/sleep 0.5

/bin/mkdir -p "${INSTALL_DIR}"
/bin/rm -rf "${OLD_APP_DIR}"
/bin/rm -rf "${INSTALLED_APP_DIR}"
/usr/bin/ditto "${APP_DIR}" "${INSTALLED_APP_DIR}"

echo "Installed: ${INSTALLED_APP_DIR}"
open "${INSTALLED_APP_DIR}"
