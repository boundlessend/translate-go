#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="OllamaTranslatorApp"
APP_BUNDLE_NAME="translate&go"
BUILD_DIR="${ROOT_DIR}/.build"
APP_DIR="${BUILD_DIR}/${APP_BUNDLE_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

cd "${ROOT_DIR}"

swift build \
  --configuration release \
  --product "${APP_NAME}" \
  --scratch-path "${BUILD_DIR}" >&2

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${BUILD_DIR}/release/${APP_NAME}" "${MACOS_DIR}/${APP_BUNDLE_NAME}"
cp "${ROOT_DIR}/Sources/${APP_NAME}/Info.plist" "${CONTENTS_DIR}/Info.plist"
cp "${ROOT_DIR}/Sources/${APP_NAME}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
chmod +x "${MACOS_DIR}/${APP_BUNDLE_NAME}"

/usr/bin/codesign --force --deep --sign - "${APP_DIR}" >&2

echo "${APP_DIR}"
