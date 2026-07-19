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
    private lazy var settingsWindowController = PanelWindowController(
        title: { [settingsViewModel] in
            "translate&go \(AppText.settingsTitle(settingsViewModel.interfaceLanguage))"
        },
        content: { [settingsViewModel] in
            SettingsView(viewModel: settingsViewModel)
        }
    )
    private lazy var qaWindowController = PanelWindowController(
        title: { "translate&go Q&A" },
        content: { [settingsViewModel] in
            QAView(viewModel: settingsViewModel)
        }
    )
    private var hotkeyManager: HotkeyManager?
    private var statusMenuController: StatusMenuController?
    private var cancellables: Set<AnyCancellable>
    private var currentTranslationTask: Task<Void, Never>?
    private var translationGeneration: Int
    private weak var lastFocusedApplication: NSRunningApplication?

    override init() {
        let diagnosticLogger = DiagnosticLogger()
        self.settingsViewModel = SettingsViewModel(userDefaults: .standard)
        self.translationService = TranslationService()
        self.diagnosticLogger = diagnosticLogger
        self.ollamaRuntimeManager = OllamaRuntimeManager(diagnosticLogger: diagnosticLogger)
        self.notificationPresenter = NotificationPresenter()
        self.permissionManager = PermissionManager(notificationPresenter: notificationPresenter)
        self.pasteboard = .general
        self.cancellables = []
        self.currentTranslationTask = nil
        self.translationGeneration = 0
        self.lastFocusedApplication = nil
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
            quit: { NSApp.terminate(nil) },
            language: settingsViewModel.interfaceLanguage
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

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        currentTranslationTask?.cancel()
        let preferredExecutablePath = settingsViewModel.trimmedOllamaExecutablePath
        let model = settingsViewModel.model
        Task { @MainActor in
            await stopOllamaRuntimeBounded(preferredExecutablePath: preferredExecutablePath, model: model)
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    /// останавливает ollama в фоне, не блокируя выход дольше таймаута
    private func stopOllamaRuntimeBounded(preferredExecutablePath: String?, model: String) async {
        let cleanup = Task.detached(priority: .userInitiated) { [ollamaRuntimeManager] in
            await ollamaRuntimeManager.stopOnApplicationExit(
                preferredExecutablePath: preferredExecutablePath,
                model: model
            )
        }
        let timeout = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await cleanup.value }
            group.addTask { await timeout.value }
            await group.next()
            group.cancelAll()
        }
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

        settingsViewModel.$interfaceLanguage
            .dropFirst()
            .sink { [weak self] language in
                Task { @MainActor in
                    self?.configureApplicationMenu()
                    self?.statusMenuController?.updateLanguage(language)
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
        let language = settingsViewModel.interfaceLanguage
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let settingsItem = NSMenuItem(
            title: AppText.settingsMenuTitle(language),
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
                title: AppText.quitTitle(language),
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

        let language = settingsViewModel.interfaceLanguage
        let alert = NSAlert()
        alert.messageText = "translate&go"
        alert.informativeText = AppText.welcomeMessage(language)
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func startOllamaRuntime() {
        Task { @MainActor in
            do {
                let baseURL = try settingsViewModel.ollamaBaseURL()
                try await ollamaRuntimeManager.startIfNeeded(
                    baseURL: baseURL,
                    preferredExecutablePath: settingsViewModel.trimmedOllamaExecutablePath,
                    model: settingsViewModel.model,
                    shouldPreloadModel: settingsViewModel.isModelPreloadEnabled
                )
            } catch {
                showTranslationError(error)
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
                "generation": String(generation),
            ]
        )
        currentTranslationTask?.cancel()
        currentTranslationTask = Task { @MainActor in
            await translateSelection(generation: generation)
        }
    }

    @MainActor
    private func translateSelection(generation: Int) async {
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
                    "textLength": String(selectedText.count),
                ]
            )
            let language = settingsViewModel.interfaceLanguage
            notificationPresenter.show(
                title: AppText.translationStartedTitle(language),
                message: AppText.translationStartedMessage(language)
            )
            diagnosticLogger.log(
                event: "translation_started",
                fields: [
                    "generation": String(generation),
                    "model": settingsViewModel.model,
                ]
            )
            let generateEndpoint = try settingsViewModel.ollamaBaseURL().appendingPathComponent("api/generate")
            let translatedText = try await translationService.translate(
                text: selectedText,
                model: settingsViewModel.model,
                targetLanguage: settingsViewModel.targetLanguageText,
                endpoint: generateEndpoint
            )
            try Task.checkCancellation()
            try checkCurrentTranslation(generation: generation)
            diagnosticLogger.log(
                event: "translation_finished",
                fields: [
                    "generation": String(generation),
                    "textLength": String(translatedText.count),
                ]
            )
            try writeTextToPasteboard(translatedText)
            diagnosticLogger.log(
                event: "pasteboard_write_finished",
                fields: ["generation": String(generation)]
            )
            notificationPresenter.show(
                title: AppText.translationReadyTitle(language),
                message: AppText.translationReadyMessage(language)
            )
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
                    "error": error.localizedDescription,
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
            text.isEmpty == false
        {
            diagnosticLogger.log(
                event: "accessibility_selection_read",
                fields: [
                    "application": lastFocusedApplication?.localizedName ?? "<none>",
                    "textLength": String(text.count),
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
        let nonTextGraceAttempts: Int = 10
        let delayNanoseconds: UInt64 = 50_000_000
        var attemptsAfterChange: Int = 0

        for _ in 0..<attempts {
            try await Task.sleep(nanoseconds: delayNanoseconds)

            guard pasteboard.changeCount != pasteboardChangeCount else {
                continue
            }

            let text = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let text else {
                // буфер уже изменился, но строки нет: короткий грейс на дозапись, затем явная ошибка
                attemptsAfterChange += 1
                guard attemptsAfterChange < nonTextGraceAttempts else {
                    throw AppError.selectedContentNotText
                }

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
        let language = settingsViewModel.interfaceLanguage
        let title = AppText.translationErrorTitle(language)
        let message = "\(error.localizedDescription)\n\n\(AppText.logLabel(language)): \(diagnosticLogger.logURLPath())"
        notificationPresenter.show(title: title, message: message)

        // модальный алерт крадёт фокус, поэтому он только для ошибок первичной настройки
        guard isSetupError(error) else {
            return
        }

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")

        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func isSetupError(_ error: Error) -> Bool {
        switch error {
        case AppError.accessibilityPermissionMissing, AppError.ollamaExecutableMissing,
            AppError.ollamaStartupTimedOut:
            return true
        default:
            return false
        }
    }
}
