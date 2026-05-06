import ApplicationServices
import AppKit
import Foundation
import UserNotifications

struct PermissionManager {
    private let notificationPresenter: NotificationPresenter

    init(notificationPresenter: NotificationPresenter) {
        self.notificationPresenter = notificationPresenter
    }

    func requestRequiredPermissions() {
        requestAccessibilityPermission()
        requestNotificationPermission()
    }

    private func requestAccessibilityPermission() {
        guard AXIsProcessTrusted() == false else {
            return
        }

        showAccessibilityInstructions()
    }

    private func showAccessibilityInstructions() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Нужно разрешение Accessibility"
            alert.informativeText = """
            Откройте System Settings → Privacy & Security → Accessibility и включите translate&go.

            Если приложение уже есть в списке, удалите старую запись, добавьте заново файл:
            /Applications/translate&go.app

            После этого перезапустите приложение через run_app.command.
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Открыть настройки")
            alert.addButton(withTitle: "Позже")

            let response = alert.runModal()
            guard response == .alertFirstButtonReturn else {
                return
            }

            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                return
            }

            self.notificationPresenter.requestAuthorization()
        }
    }
}
