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
            let language = AppText.currentLanguage()
            let alert = NSAlert()
            alert.messageText = AppText.accessibilityPermissionTitle(language)
            alert.informativeText = AppText.accessibilityPermissionMessage(language)
            alert.alertStyle = .warning
            alert.addButton(withTitle: AppText.openSettingsButton(language))
            alert.addButton(withTitle: AppText.laterButton(language))

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
