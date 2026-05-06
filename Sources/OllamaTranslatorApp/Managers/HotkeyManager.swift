import AppKit
import HotKey

@MainActor
final class HotkeyManager {
    private let settingsViewModel: SettingsViewModel
    private var hotKey: HotKey?
    private var handler: (() -> Void)?

    init(settingsViewModel: SettingsViewModel) {
        self.settingsViewModel = settingsViewModel
    }

    func setHandler(_ handler: @escaping () -> Void) {
        self.handler = handler
        self.hotKey?.keyDownHandler = handler
    }

    func registerConfiguredHotkey() {
        let configuration = settingsViewModel.hotkeyConfiguration
        let newHotKey = HotKey(keyCombo: configuration.keyCombo)
        newHotKey.keyDownHandler = handler
        self.hotKey = newHotKey
    }
}
