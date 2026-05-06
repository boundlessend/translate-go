import AppKit
import SwiftUI

struct HotkeyRecorderView: NSViewRepresentable {
    let onRecord: (Result<HotkeyConfiguration, Error>) -> Void

    func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.onRecord = onRecord
        return view
    }

    func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {
        nsView.onRecord = onRecord
    }
}

final class HotkeyRecorderNSView: NSView {
    var onRecord: ((Result<HotkeyConfiguration, Error>) -> Void)?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        do {
            let configuration = try HotkeyConfiguration.make(event: event)
            onRecord?(.success(configuration))
        } catch {
            onRecord?(.failure(error))
        }
    }
}
