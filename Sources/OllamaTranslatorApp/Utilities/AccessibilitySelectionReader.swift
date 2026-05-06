import ApplicationServices
import AppKit
import Foundation

enum AccessibilitySelectionReader {
    static func readSelectedText(from application: NSRunningApplication?) -> String? {
        guard let processIdentifier = application?.processIdentifier else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(processIdentifier)
        guard let focusedElement = copyElementAttribute(
            from: appElement,
            attribute: kAXFocusedUIElementAttribute
        ) else {
            return nil
        }

        return copyStringAttribute(
            from: focusedElement,
            attribute: kAXSelectedTextAttribute
        )
    }

    private static func copyElementAttribute(from element: AXUIElement, attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        guard result == .success else {
            return nil
        }

        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }

        let element = value as! AXUIElement
        return element
    }

    private static func copyStringAttribute(from element: AXUIElement, attribute: String) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        guard result == .success else {
            return nil
        }

        let text = value as? String
        return text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
