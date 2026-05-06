import AppKit
import Carbon
import Foundation
import HotKey

struct HotkeyConfiguration: Codable, Equatable {
    let carbonKeyCode: UInt32
    let carbonModifiers: UInt32
    let title: String

    var keyCombo: KeyCombo {
        KeyCombo(carbonKeyCode: carbonKeyCode, carbonModifiers: carbonModifiers)
    }

    static func controlC() -> HotkeyConfiguration {
        HotkeyConfiguration(
            carbonKeyCode: UInt32(kVK_ANSI_C),
            carbonModifiers: NSEvent.ModifierFlags.control.carbonFlags,
            title: "⌃C"
        )
    }

    static func make(event: NSEvent) throws -> HotkeyConfiguration {
        let modifiers = normalizedModifiers(event.modifierFlags)
        guard modifiers.isEmpty == false else {
            throw AppError.hotkeyRequiresModifier
        }

        guard ignoredKeyCodes().contains(UInt32(event.keyCode)) == false else {
            throw AppError.hotkeyInvalidKey
        }

        let keyTitle = keyDisplayName(event: event)
        guard keyTitle.isEmpty == false else {
            throw AppError.hotkeyInvalidKey
        }

        return HotkeyConfiguration(
            carbonKeyCode: UInt32(event.keyCode),
            carbonModifiers: modifiers.carbonFlags,
            title: "\(modifierDisplayName(modifiers))\(keyTitle)"
        )
    }

    static func decode(data: Data) -> HotkeyConfiguration? {
        try? JSONDecoder().decode(HotkeyConfiguration.self, from: data)
    }

    func encode() -> Data? {
        try? JSONEncoder().encode(self)
    }

    private static func normalizedModifiers(_ modifiers: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        modifiers.intersection([.command, .option, .control, .shift])
    }

    private static func ignoredKeyCodes() -> Set<UInt32> {
        Set([
            UInt32(kVK_Command),
            UInt32(kVK_RightCommand),
            UInt32(kVK_Shift),
            UInt32(kVK_RightShift),
            UInt32(kVK_Option),
            UInt32(kVK_RightOption),
            UInt32(kVK_Control),
            UInt32(kVK_RightControl),
            UInt32(kVK_Function),
            UInt32(kVK_CapsLock)
        ])
    }

    private static func modifierDisplayName(_ modifiers: NSEvent.ModifierFlags) -> String {
        [
            modifiers.contains(.control) ? "⌃" : "",
            modifiers.contains(.option) ? "⌥" : "",
            modifiers.contains(.shift) ? "⇧" : "",
            modifiers.contains(.command) ? "⌘" : ""
        ].joined()
    }

    private static func keyDisplayName(event: NSEvent) -> String {
        if let carbonKeyName = carbonKeyDisplayName(UInt32(event.keyCode)) {
            return carbonKeyName
        }

        let characters = event.charactersIgnoringModifiers ?? ""
        return characters.uppercased()
    }

    private static func carbonKeyDisplayName(_ keyCode: UInt32) -> String? {
        switch keyCode {
        case UInt32(kVK_UpArrow):
            return "↑"
        case UInt32(kVK_DownArrow):
            return "↓"
        case UInt32(kVK_LeftArrow):
            return "←"
        case UInt32(kVK_RightArrow):
            return "→"
        case UInt32(kVK_Escape):
            return "Esc"
        case UInt32(kVK_Delete):
            return "⌫"
        case UInt32(kVK_Home):
            return "Home"
        case UInt32(kVK_End):
            return "End"
        case UInt32(kVK_PageUp):
            return "Page Up"
        case UInt32(kVK_PageDown):
            return "Page Down"
        case UInt32(kVK_Tab):
            return "Tab"
        case UInt32(kVK_Return):
            return "Return"
        case UInt32(kVK_F1):
            return "F1"
        case UInt32(kVK_F2):
            return "F2"
        case UInt32(kVK_F3):
            return "F3"
        case UInt32(kVK_F4):
            return "F4"
        case UInt32(kVK_F5):
            return "F5"
        case UInt32(kVK_F6):
            return "F6"
        case UInt32(kVK_F7):
            return "F7"
        case UInt32(kVK_F8):
            return "F8"
        case UInt32(kVK_F9):
            return "F9"
        case UInt32(kVK_F10):
            return "F10"
        case UInt32(kVK_F11):
            return "F11"
        case UInt32(kVK_F12):
            return "F12"
        default:
            return nil
        }
    }
}
