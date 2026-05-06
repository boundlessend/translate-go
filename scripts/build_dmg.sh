#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE_NAME="translate&go"
BUILD_DIR="${ROOT_DIR}/.build"
DMG_ROOT="${BUILD_DIR}/dmg-root"
RW_DMG_PATH="${BUILD_DIR}/translate-go-rw.dmg"
DMG_PATH="${BUILD_DIR}/translate-go.dmg"
VOLUME_NAME="translate&go"
BACKGROUND_DIR_NAME=".background"
BACKGROUND_FILE_NAME="background.png"
APP_ICON_PATH="${ROOT_DIR}/Sources/OllamaTranslatorApp/Resources/AppIcon.icns"
APP_DIR="$("${ROOT_DIR}/scripts/build_app.sh")"
AUTO_FIX_PATH="${ROOT_DIR}/Auto Fix.app"
INSTRUCTION_PATH="${ROOT_DIR}/Инструкция.pdf"

create_background() {
  local output_path="$1"
  /usr/bin/swift - "${output_path}" <<'SWIFT'
import AppKit
import Foundation

let arguments: [String] = CommandLine.arguments
let outputPath: String = arguments[1]
let size: NSSize = NSSize(width: 980, height: 610)
let image: NSImage = NSImage(size: size)

image.lockFocus()

let bounds: NSRect = NSRect(origin: .zero, size: size)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.12, alpha: 1.0),
    NSColor(calibratedRed: 0.03, green: 0.24, blue: 0.30, alpha: 1.0),
    NSColor(calibratedRed: 0.14, green: 0.07, blue: 0.24, alpha: 1.0),
    NSColor(calibratedRed: 0.03, green: 0.04, blue: 0.08, alpha: 1.0)
])
gradient?.draw(in: bounds, angle: 32)

let shapes: [(NSColor, NSRect)] = [
    (NSColor(calibratedRed: 0.00, green: 0.92, blue: 0.78, alpha: 0.24), NSRect(x: 640, y: 310, width: 420, height: 420)),
    (NSColor(calibratedRed: 1.00, green: 0.34, blue: 0.70, alpha: 0.22), NSRect(x: -100, y: 300, width: 360, height: 360)),
    (NSColor(calibratedRed: 1.00, green: 0.72, blue: 0.18, alpha: 0.18), NSRect(x: 130, y: -150, width: 420, height: 420)),
    (NSColor(calibratedRed: 0.35, green: 0.44, blue: 1.00, alpha: 0.20), NSRect(x: 610, y: -95, width: 340, height: 340))
]

for shape in shapes {
    shape.0.setFill()
    NSBezierPath(ovalIn: shape.1).fill()
}

for index in 0..<18 {
    let x = CGFloat((index * 127) % 980)
    let y = CGFloat((index * 71) % 610)
    let length = CGFloat(54 + (index % 5) * 18)
    let path = NSBezierPath()
    path.lineWidth = CGFloat(1 + index % 2)
    NSColor(calibratedWhite: 1.0, alpha: 0.07).setStroke()
    path.move(to: NSPoint(x: x, y: y))
    path.line(to: NSPoint(x: min(x + length, 980), y: min(y + length * 0.36, 610)))
    path.stroke()
}

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 34, weight: .bold),
    .foregroundColor: NSColor.white
]
let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 15, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.88, alpha: 0.92)
]

"translate&go".draw(at: NSPoint(x: 34, y: 550), withAttributes: titleAttributes)
"Local text translation in one hotkey".draw(at: NSPoint(x: 36, y: 526), withAttributes: subtitleAttributes)

let lineColor = NSColor(calibratedWhite: 1.0, alpha: 0.18)
lineColor.setStroke()
let path = NSBezierPath()
path.lineWidth = 2
path.move(to: NSPoint(x: 38, y: 506))
path.line(to: NSPoint(x: 942, y: 506))
path.stroke()

let stepTitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
    .foregroundColor: NSColor.white
]
let stepTextAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 12.5, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.91, alpha: 0.96)
]
let stepBoxColor = NSColor(calibratedWhite: 1.0, alpha: 0.13)
let stepBorderColor = NSColor(calibratedWhite: 1.0, alpha: 0.18)
let steps: [(String, String, NSPoint)] = [
    ("1", "Drag app to Applications", NSPoint(x: 38, y: 82)),
    ("2", "Try to open the app", NSPoint(x: 346, y: 82)),
    ("3", "Allow Accessibility", NSPoint(x: 654, y: 82)),
    ("4", "Install Ollama", NSPoint(x: 38, y: 26)),
    ("5", "Pull translation model", NSPoint(x: 346, y: 26)),
    ("6", "Choose model and hotkey", NSPoint(x: 654, y: 26))
]

for step in steps {
    let box = NSRect(x: step.2.x, y: step.2.y, width: 270, height: 42)
    let boxPath = NSBezierPath(roundedRect: box, xRadius: 12, yRadius: 12)
    stepBoxColor.setFill()
    boxPath.fill()
    stepBorderColor.setStroke()
    boxPath.lineWidth = 1
    boxPath.stroke()

    let circle = NSRect(x: step.2.x + 10, y: step.2.y + 10, width: 22, height: 22)
    NSColor(calibratedRed: 0.00, green: 0.86, blue: 0.74, alpha: 0.88).setFill()
    NSBezierPath(ovalIn: circle).fill()
    step.0.draw(at: NSPoint(x: step.2.x + 17, y: step.2.y + 12), withAttributes: stepTitleAttributes)
    step.1.draw(at: NSPoint(x: step.2.x + 42, y: step.2.y + 13), withAttributes: stepTextAttributes)
}

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    exit(1)
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
SWIFT
}

write_installation_guide() {
  local output_path="$1"
  cat > "${output_path}" <<'EOF'
Как установить translate&go

1. Переместите translate&go.app в Applications

Откройте этот DMG и перетащите translate&go.app в папку Applications.
Запускать приложение прямо из DMG не нужно: macOS может не сохранить разрешения корректно.

2. Попробуйте запустить translate&go

Откройте Applications и запустите translate&go.
Если macOS покажет предупреждение безопасности, используйте стандартный способ macOS:
Control-click по translate&go.app -> Open -> Open.

3. Разрешите Accessibility

Откройте System Settings -> Privacy & Security -> Accessibility и включите translate&go.
Если приложение уже есть в списке, удалите старую запись и добавьте /Applications/translate&go.app заново.

4. Установите Ollama

Установите Ollama с https://ollama.com и проверьте, что команда ollama доступна в Terminal.

5. Скачайте модель

Например:
ollama pull translategemma:12b

6. Настройте приложение

Откройте Settings, выберите модель, язык перевода и хоткей.

Готово.
EOF
}

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
  set bounds of targetWindow to {120, 100, 1100, 710}
  set theViewOptions to the icon view options of targetWindow
  set arrangement of theViewOptions to not arranged
  set icon size of theViewOptions to 72
  set background picture of theViewOptions to POSIX file "${mount_path}/${BACKGROUND_DIR_NAME}/${BACKGROUND_FILE_NAME}"
  set position of item "${APP_BUNDLE_NAME}.app" of targetFolder to {138, 198}
  set position of item "Applications" of targetFolder to {812, 198}
  update targetFolder without registering applications
  delay 2
  close targetWindow
end tell
APPLESCRIPT
}

rm -rf "${DMG_ROOT}"
rm -f "${RW_DMG_PATH}" "${DMG_PATH}"
mkdir -p "${DMG_ROOT}/${BACKGROUND_DIR_NAME}"

/usr/bin/ditto "${APP_DIR}" "${DMG_ROOT}/${APP_BUNDLE_NAME}.app"
ln -s /Applications "${DMG_ROOT}/Applications"
create_background "${DMG_ROOT}/${BACKGROUND_DIR_NAME}/${BACKGROUND_FILE_NAME}"
write_installation_guide "${DMG_ROOT}/Как установить.txt"

if [[ -e "${AUTO_FIX_PATH}" ]]; then
  /usr/bin/ditto "${AUTO_FIX_PATH}" "${DMG_ROOT}/Auto Fix.app"
fi

if [[ -e "${INSTRUCTION_PATH}" ]]; then
  /usr/bin/ditto "${INSTRUCTION_PATH}" "${DMG_ROOT}/Инструкция.pdf"
fi

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

/usr/bin/SetFile -a V "${MOUNT_PATH}/${BACKGROUND_DIR_NAME}"
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
