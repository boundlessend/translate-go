import SwiftUI

@main
struct OllamaTranslatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // настройки открываются собственным контроллером окна, пустая сцена нужна только жизненному циклу swiftui
        Settings {
            EmptyView()
        }
    }
}
