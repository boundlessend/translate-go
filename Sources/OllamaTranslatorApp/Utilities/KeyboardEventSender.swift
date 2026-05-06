import AppKit

enum KeyboardEventSender {
    static func sendCommandC() throws {
        let keyCodeForC: CGKeyCode = 8
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            throw AppError.unexpected(NSError(domain: "KeyboardEventSender", code: 1))
        }

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForC, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForC, keyDown: false) else {
            throw AppError.unexpected(NSError(domain: "KeyboardEventSender", code: 2))
        }

        // CGEvent использует маску события, поэтому модификатор нужно назначать на оба события.
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
