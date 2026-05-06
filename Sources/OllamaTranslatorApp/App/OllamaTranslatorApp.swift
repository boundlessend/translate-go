import SwiftUI

@main
struct OllamaTranslatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(viewModel: appDelegate.settingsViewModel)
        }
    }
}
