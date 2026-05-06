import AppKit
import Carbon
import Foundation
import HotKey

struct HotkeyValidator {
    func validate(candidate: HotkeyConfiguration, current: HotkeyConfiguration) throws {
        if isReservedBySystem(candidate.keyCombo) {
            throw AppError.hotkeyReservedBySystem(hotkey: candidate.title)
        }

        guard candidate == current else {
            try validateRegistration(candidate)
            return
        }
    }

    private func isReservedBySystem(_ keyCombo: KeyCombo) -> Bool {
        let reservedCombos = KeyCombo.systemKeyCombos()
            + KeyCombo.standardKeyCombos()
            + KeyCombo.mainMenuKeyCombos()

        return reservedCombos.contains(keyCombo)
    }

    private func validateRegistration(_ configuration: HotkeyConfiguration) throws {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x7472676F), id: UInt32.random(in: 1...UInt32.max))
        let status = RegisterEventHotKey(
            configuration.carbonKeyCode,
            configuration.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        guard status == noErr else {
            throw AppError.hotkeyRegistrationFailed(hotkey: configuration.title)
        }
    }
}
