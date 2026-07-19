import AppKit
import SwiftUI

/// переиспользуемое окно со swiftui-содержимым: создаётся лениво и переживает закрытие
@MainActor
final class PanelWindowController<Content: View> {
    private let title: () -> String
    private let content: () -> Content
    private var window: NSWindow?

    init(title: @escaping () -> String, content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    func showWindow() {
        let window = existingOrNewWindow()
        window.title = title()
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func existingOrNewWindow() -> NSWindow {
        if let window {
            return window
        }

        let hostingController = NSHostingController(rootView: content())
        let window = NSWindow(contentViewController: hostingController)

        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        self.window = window
        return window
    }
}
