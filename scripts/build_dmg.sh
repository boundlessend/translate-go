#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE_NAME="translate&go"
BUILD_DIR="${ROOT_DIR}/.build"
DMG_ROOT="${BUILD_DIR}/dmg-root"
RW_DMG_PATH="${BUILD_DIR}/translate-go-rw.dmg"
DMG_PATH="${BUILD_DIR}/translate-go.dmg"
VOLUME_NAME="translate&go"
APP_DIR="$("${ROOT_DIR}/scripts/build_app.sh")"

configure_finder_window() {
  local mount_path="$1"
  /usr/bin/osascript <<APPLESCRIPT
tell application "Finder"
  set targetFolder to POSIX file "${mount_path}" as alias
  try
    close container window of targetFolder
  end try
  open targetFolder
  delay 1
  set targetWindow to container window of targetFolder
  set current view of targetWindow to icon view
  try
    set toolbar visible of targetWindow to false
  end try
  try
    set statusbar visible of targetWindow to false
  end try
  set bounds of targetWindow to {120, 100, 620, 420}
  set theViewOptions to the icon view options of targetWindow
  set arrangement of theViewOptions to not arranged
  set icon size of theViewOptions to 72
  set position of item "${APP_BUNDLE_NAME}.app" of targetFolder to {140, 145}
  set position of item "Applications" of targetFolder to {360, 145}
  update targetFolder without registering applications
  delay 2
  try
    close targetWindow
  end try
end tell
APPLESCRIPT
}

rm -rf "${DMG_ROOT}"
rm -f "${RW_DMG_PATH}" "${DMG_PATH}"
mkdir -p "${DMG_ROOT}"

/usr/bin/ditto "${APP_DIR}" "${DMG_ROOT}/${APP_BUNDLE_NAME}.app"
ln -s /Applications "${DMG_ROOT}/Applications"

/usr/bin/hdiutil create \
  -volname "${VOLUME_NAME}" \
  -srcfolder "${DMG_ROOT}" \
  -ov \
  -format UDRW \
  -fs HFS+ \
  "${RW_DMG_PATH}" >&2

MOUNT_OUTPUT="$(/usr/bin/hdiutil attach -readwrite -nobrowse "${RW_DMG_PATH}")"
MOUNT_PATH="$(printf '%s\n' "${MOUNT_OUTPUT}" | awk -F '\t' '/\/Volumes\// { print $NF; exit }')"

if [[ -z "${MOUNT_PATH}" ]]; then
  echo "Failed to mount temporary DMG." >&2
  exit 1
fi

configure_finder_window "${MOUNT_PATH}"
/bin/sync
/bin/sleep 1
/usr/bin/hdiutil detach "${MOUNT_PATH}" >&2

/usr/bin/hdiutil convert "${RW_DMG_PATH}" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "${DMG_PATH}" >&2

/usr/bin/xattr -d com.apple.FinderInfo "${DMG_PATH}" 2>/dev/null || true
/usr/bin/xattr -d com.apple.ResourceFork "${DMG_PATH}" 2>/dev/null || true

rm -f "${RW_DMG_PATH}"
echo "${DMG_PATH}"
