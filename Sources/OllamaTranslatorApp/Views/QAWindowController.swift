import AppKit
import SwiftUI

@MainActor
final class QAWindowController {
    private let viewModel: SettingsViewModel
    private var window: NSWindow?

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    func showWindow() {
        let window = existingOrNewWindow()
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func existingOrNewWindow() -> NSWindow {
        if let window {
            return window
        }

        let rootView = QAView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)

        window.title = "translate&go Q&A"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        self.window = window
        return window
    }
}
