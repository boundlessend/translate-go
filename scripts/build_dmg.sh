#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/.build"
DMG_PATH="${BUILD_DIR}/translate-go.dmg"
VOLUME_NAME="translate&go"
APP_DIR="$("${ROOT_DIR}/scripts/build_app.sh")"
GENERATED_DMG_PATH="${BUILD_DIR}/${VOLUME_NAME}.dmg"

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "create-dmg is required to build the DMG locally." >&2
  exit 1
fi

rm -f "${DMG_PATH}"
rm -f "${GENERATED_DMG_PATH}"

create-dmg \
  --overwrite \
  --no-version-in-filename \
  --dmg-title="${VOLUME_NAME}" \
  --no-code-sign \
  "${APP_DIR}" \
  "${BUILD_DIR}" >&2

if [[ -f "${GENERATED_DMG_PATH}" && "${GENERATED_DMG_PATH}" != "${DMG_PATH}" ]]; then
  mv "${GENERATED_DMG_PATH}" "${DMG_PATH}"
fi

/usr/bin/codesign --force --sign - "${DMG_PATH}" >&2

echo "${DMG_PATH}"
