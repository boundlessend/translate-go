import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsViewModel: SettingsViewModel

    private let translationService: TranslationService
    private let ollamaRuntimeManager: OllamaRuntimeManager
    private let notificationPresenter: NotificationPresenter
    private let permissionManager: PermissionManager
    private let diagnosticLogger: DiagnosticLogger
    private let pasteboard: NSPasteboard
    private lazy var settingsWindowController: SettingsWindowController = {
        SettingsWindowController(viewModel: settingsViewModel)
    }()
    private lazy var qaWindowController: QAWindowController = {
        QAWindowController()
    }()
    private var hotkeyManager: HotkeyManager?
    private var statusMenuController: StatusMenuController?
    private var cancellables: Set<AnyCancellable>
    private var currentTranslationTask: Task<Void, Never>?
    private var translationGeneration: Int
    private weak var lastFocusedApplication: NSRunningApplication?
    private var isTranslating: Bool

    override init() {
        let diagnosticLogger = DiagnosticLogger()
        self.settingsViewModel = SettingsViewModel(userDefaults: .standard)
        self.translationService = TranslationService(
            ollamaEndpoint: URL(string: "http://localhost:11434/api/generate")!
        )
        self.diagnosticLogger = diagnosticLogger
        self.ollamaRuntimeManager = OllamaRuntimeManager(
            tagsEndpoint: URL(string: "http://localhost:11434/api/tags")!,
            generateEndpoint: URL(string: "http://localhost:11434/api/generate")!,
            model: OllamaModelPreset.translateGemma12b.rawValue,
            diagnosticLogger: diagnosticLogger
        )
        self.notificationPresenter = NotificationPresenter()
        self.permissionManager = PermissionManager(notificationPresenter: notificationPresenter)
        self.pasteboard = .general
        self.cancellables = []
        self.currentTranslationTask = nil
        self.translationGeneration = 0
        self.lastFocusedApplication = nil
        self.isTranslating = false
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        startOllamaRuntime()
        permissionManager.requestRequiredPermissions()
        configureApplicationMenu()

        let manager = HotkeyManager(settingsViewModel: settingsViewModel)
        manager.setHandler { [weak self] in
            self?.restartTranslation()
        }
        manager.registerConfiguredHotkey()
        self.hotkeyManager = manager

        let menuController = StatusMenuController(
            openSettings: { [weak self] in self?.openSettingsWindow() },
            openQA: { [weak self] in self?.openQAWindow() },
            quit: { NSApp.terminate(nil) }
        )
        self.statusMenuController = menuController

        applyInterfaceVisibility(
            isDockVisible: settingsViewModel.isDockVisible,
            isMenuBarVisible: settingsViewModel.isMenuBarVisible
        )
        observeSettings()
        showWelcomeIfNeeded()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettingsWindow()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        currentTranslationTask?.cancel()
        ollamaRuntimeManager.stopOnApplicationExit()
    }

    private func observeSettings() {
        settingsViewModel.$hotkeyConfiguration
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.hotkeyManager?.registerConfiguredHotkey()
                }
            }
            .store(in: &cancellables)

        settingsViewModel.$isDockVisible
            .dropFirst()
            .sink { [weak self] isDockVisible in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    self.applyInterfaceVisibility(
                        isDockVisible: isDockVisible,
                        isMenuBarVisible: self.settingsViewModel.isMenuBarVisible
                    )
                }
            }
            .store(in: &cancellables)

        settingsViewModel.$isMenuBarVisible
            .dropFirst()
            .sink { [weak self] isMenuBarVisible in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    self.applyInterfaceVisibility(
                        isDockVisible: self.settingsViewModel.isDockVisible,
                        isMenuBarVisible: isMenuBarVisible
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func applyInterfaceVisibility(isDockVisible: Bool, isMenuBarVisible: Bool) {
        if isDockVisible {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }

        statusMenuController?.setVisible(isMenuBarVisible)
    }

    private func openSettingsWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController.showWindow()
        applyInterfaceVisibility(
            isDockVisible: settingsViewModel.isDockVisible,
            isMenuBarVisible: settingsViewModel.isMenuBarVisible
        )
    }

    private func openQAWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        qaWindowController.showWindow()
        applyInterfaceVisibility(
            isDockVisible: settingsViewModel.isDockVisible,
            isMenuBarVisible: settingsViewModel.isMenuBarVisible
        )
    }

    private func configureApplicationMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ","
        )

        settingsItem.target = self
        appMenu.addItem(settingsItem)
        let copyrightItem = NSMenuItem(title: "© boundlessend", action: nil, keyEquivalent: "")
        copyrightItem.isEnabled = false
        appMenu.addItem(copyrightItem)
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Quit translate&go",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    @objc private func openSettingsFromMenu() {
        openSettingsWindow()
    }

    private func showWelcomeIfNeeded() {
        let key = "hasShownWelcomeMessage"
        guard UserDefaults.standard.bool(forKey: key) == false else {
            return
        }

        UserDefaults.standard.set(true, forKey: key)

        let alert = NSAlert()
        alert.messageText = "translate&go"
        alert.informativeText = "привет! спасибо за выбор моей проги, надеюсь она будет полезна! по всем вопросам пиши @boundlessend"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func startOllamaRuntime() {
        Task {
            do {
                try await ollamaRuntimeManager.startIfNeeded()
            } catch {
                await MainActor.run {
                    showTranslationError(error)
                }
            }
        }
    }

    private func restartTranslation() {
        translationGeneration += 1
        let generation = translationGeneration
        lastFocusedApplication = NSWorkspace.shared.frontmostApplication
        diagnosticLogger.log(
            event: "hotkey_received",
            fields: [
                "frontmostApplication": lastFocusedApplication?.localizedName ?? "<none>",
                "generation": String(generation)
            ]
        )
        currentTranslationTask?.cancel()
        currentTranslationTask = Task { @MainActor in
            await translateSelection(generation: generation)
        }
    }

    @MainActor
    private func translateSelection(generation: Int) async {
        isTranslating = true
        defer {
            isTranslating = false
        }

        let pasteboardSnapshot = PasteboardSnapshot(pasteboard: pasteboard)

        do {
            diagnosticLogger.log(
                event: "copy_selection_started",
                fields: ["generation": String(generation)]
            )
            let selectedText = try await readSelectedText()
            try Task.checkCancellation()
            try checkCurrentTranslation(generation: generation)
            diagnosticLogger.log(
                event: "copy_selection_finished",
                fields: [
                    "generation": String(generation),
                    "textLength": String(selectedText.count)
                ]
            )
            notificationPresenter.show(title: "Перевод начат", message: "Результат появится в буфере обмена после готовности.")
            diagnosticLogger.log(
                event: "translation_started",
                fields: [
                    "generation": String(generation),
                    "model": settingsViewModel.model
                ]
            )
            let translatedText = try await translationService.translate(
                text: selectedText,
                model: settingsViewModel.model,
                targetLanguage: settingsViewModel.targetLanguageText
            )
            try Task.checkCancellation()
            try checkCurrentTranslation(generation: generation)
            diagnosticLogger.log(
                event: "translation_finished",
                fields: [
                    "generation": String(generation),
                    "textLength": String(translatedText.count)
                ]
            )
            try writeTextToPasteboard(translatedText)
            diagnosticLogger.log(
                event: "pasteboard_write_finished",
                fields: ["generation": String(generation)]
            )
            notificationPresenter.show(title: "Перевод готов", message: "Текст записан в буфер обмена.")
        } catch is CancellationError {
            diagnosticLogger.log(
                event: "translation_cancelled",
                fields: ["generation": String(generation)]
            )
            return
        } catch {
            diagnosticLogger.log(
                event: "translation_failed",
                fields: [
                    "generation": String(generation),
                    "error": error.localizedDescription
                ]
            )
            do {
                try pasteboardSnapshot.restore(to: pasteboard)
            } catch {
                showTranslationError(error)
                return
            }

            showTranslationError(error)
        }
    }

    @MainActor
    private func readSelectedText() async throws -> String {
        guard AXIsProcessTrusted() else {
            throw AppError.accessibilityPermissionMissing
        }

        if let text = AccessibilitySelectionReader.readSelectedText(from: lastFocusedApplication),
           text.isEmpty == false {
            diagnosticLogger.log(
                event: "accessibility_selection_read",
                fields: [
                    "application": lastFocusedApplication?.localizedName ?? "<none>",
                    "textLength": String(text.count)
                ]
            )
            return text
        }

        diagnosticLogger.log(
            event: "accessibility_selection_unavailable",
            fields: ["application": lastFocusedApplication?.localizedName ?? "<none>"]
        )

        lastFocusedApplication?.activate(options: [])
        try await Task.sleep(nanoseconds: 250_000_000)

        let pasteboardChangeCount = pasteboard.changeCount
        try KeyboardEventSender.sendCommandC()

        let text = try await waitForSelectedText(after: pasteboardChangeCount)

        return text
    }

    @MainActor
    private func waitForSelectedText(after pasteboardChangeCount: Int) async throws -> String {
        let attempts: Int = 100
        let delayNanoseconds: UInt64 = 50_000_000

        for _ in 0..<attempts {
            try await Task.sleep(nanoseconds: delayNanoseconds)

            guard pasteboard.changeCount != pasteboardChangeCount else {
                continue
            }

            let text = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let text else {
                continue
            }

            guard text.isEmpty == false else {
                throw AppError.emptyPasteboard
            }

            return text
        }

        throw AppError.copySelectionTimedOut
    }

    private func writeTextToPasteboard(_ text: String) throws {
        pasteboard.clearContents()
        let isWritten = pasteboard.setString(text, forType: .string)
        guard isWritten else {
            throw AppError.pasteboardWriteFailed
        }
    }

    private func checkCurrentTranslation(generation: Int) throws {
        guard generation == translationGeneration else {
            throw CancellationError()
        }
    }

    private func showTranslationError(_ error: Error) {
        let message = "\(error.localizedDescription)\n\nЛог: \(diagnosticLogger.logURLPath())"
        notificationPresenter.show(title: "Ошибка перевода", message: message)

        let alert = NSAlert()
        alert.messageText = "Ошибка перевода"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")

        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
