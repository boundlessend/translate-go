import AppKit

@MainActor
final class StatusMenuController {
    private let statusItem: NSStatusItem
    private let menu: NSMenu
    private let settingsItem: NSMenuItem
    private let quitItem: NSMenuItem

    init(openSettings: @escaping () -> Void, openQA: @escaping () -> Void, quit: @escaping () -> Void, language: AppLanguage) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.menu = NSMenu()

        let settingsItem = NSMenuItem(title: "", action: #selector(MenuActionTarget.openSettings), keyEquivalent: ",")
        let qaItem = NSMenuItem(title: "Q&A", action: #selector(MenuActionTarget.openQA), keyEquivalent: "")
        let quitItem = NSMenuItem(title: "", action: #selector(MenuActionTarget.quit), keyEquivalent: "q")
        let target = MenuActionTarget(openSettings: openSettings, openQA: openQA, quit: quit)
        self.settingsItem = settingsItem
        self.quitItem = quitItem

        settingsItem.target = target
        qaItem.target = target
        quitItem.target = target
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")
        qaItem.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Q&A")
        menu.addItem(settingsItem)
        menu.addItem(qaItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        configureStatusButton(language: language)
        updateLanguage(language)
        statusItem.menu = menu
        statusItem.isVisible = false

        objc_setAssociatedObject(menu, Unmanaged.passUnretained(self).toOpaque(), target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func setVisible(_ isVisible: Bool) {
        statusItem.isVisible = isVisible
    }

    func updateLanguage(_ language: AppLanguage) {
        settingsItem.title = AppText.settingsTitle(language)
        quitItem.title = AppText.quitTitle(language)
        statusItem.button?.image?.accessibilityDescription = AppText.statusItemDescription(language)
    }

    private func configureStatusButton(language: AppLanguage) {
        guard let button = statusItem.button else {
            return
        }

        let image = NSImage(systemSymbolName: "character.bubble", accessibilityDescription: AppText.statusItemDescription(language))
        image?.isTemplate = true

        button.title = ""
        button.image = image
        button.imagePosition = .imageOnly
    }
}

private final class MenuActionTarget: NSObject {
    private let openSettingsAction: () -> Void
    private let openQAAction: () -> Void
    private let quitAction: () -> Void

    init(openSettings: @escaping () -> Void, openQA: @escaping () -> Void, quit: @escaping () -> Void) {
        self.openSettingsAction = openSettings
        self.openQAAction = openQA
        self.quitAction = quit
    }

    @objc func openSettings() {
        openSettingsAction()
    }

    @objc func openQA() {
        openQAAction()
    }

    @objc func quit() {
        quitAction()
    }
}
