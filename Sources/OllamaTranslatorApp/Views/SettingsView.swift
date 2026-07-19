import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var isRefreshingModels = false
    @State private var isRecordingHotkey = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isAlertVisible = false
    @State private var isCheckingUpdate = false
    @State private var updateResult: UpdateCheckResult?

    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    private let modelSearchURL = URL(string: "https://ollama.com/search")!

    var body: some View {
        let language = viewModel.interfaceLanguage

        Form {
            Section {
                Picker(AppText.modelLabel(language), selection: $viewModel.model) {
                    ForEach(viewModel.modelOptions, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }

                HStack {
                    busyButton(AppText.refreshModelsButton(language), isBusy: isRefreshingModels) {
                        refreshModels()
                    }

                    openURLButton(AppText.downloadModelButton(language), url: modelSearchURL)
                }

                TextField(AppText.targetLanguagePlaceholder(language), text: $viewModel.targetLanguageText)
                    .textFieldStyle(.roundedBorder)

                Picker(AppText.interfaceLanguageLabel(language), selection: $viewModel.interfaceLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
            }

            Section {
                TextField(AppText.ollamaServerURLLabel(language), text: $viewModel.ollamaBaseURLText)
                    .textFieldStyle(.roundedBorder)

                TextField(AppText.ollamaExecutablePathLabel(language), text: $viewModel.ollamaExecutablePathText)
                    .textFieldStyle(.roundedBorder)

                Toggle(AppText.preloadModelToggle(language), isOn: $viewModel.isModelPreloadEnabled)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.hotkeyLabel(language))
                        .font(.headline)

                    HStack {
                        Text(viewModel.hotkeyConfiguration.title)
                            .font(.system(.title3, design: .monospaced))
                            .frame(width: 90, alignment: .leading)

                        Button(
                            isRecordingHotkey ? AppText.pressShortcutButton(language) : AppText.changeButton(language)
                        ) {
                            isRecordingHotkey = true
                        }

                        Button(AppText.resetButton(language)) {
                            resetHotkey()
                        }
                    }

                    if isRecordingHotkey {
                        HStack(spacing: 10) {
                            HotkeyRecorderView { result in
                                handleHotkeyRecord(result)
                            }
                            .frame(height: 28)
                            .background(Color(nsColor: .selectedControlColor).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            Button(AppText.cancelButton(language)) {
                                isRecordingHotkey = false
                            }
                        }
                    }
                }

                Toggle(AppText.showDockToggle(language), isOn: $viewModel.isDockVisible)
                Toggle(AppText.showMenuBarToggle(language), isOn: $viewModel.isMenuBarVisible)
            }

            Section {
                HStack {
                    Text(AppText.currentVersionLabel(language))
                    Spacer()
                    Text(currentVersion)
                        .foregroundStyle(.secondary)
                }

                busyButton(AppText.checkUpdateButton(language), isBusy: isCheckingUpdate) {
                    checkForUpdate()
                }

                if let result = updateResult {
                    if result.isUpdateAvailable {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(AppText.updateAvailableMessage(language, version: result.latestVersion))
                                .foregroundStyle(.secondary)
                            openURLButton(AppText.openReleaseButton(language), url: result.releaseURL)
                        }
                    } else {
                        Text(AppText.upToDateMessage(language))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Text("© boundlessend")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 480)
        .task {
            refreshModels()
        }
        .alert(alertTitle, isPresented: $isAlertVisible) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    private func busyButton(_ title: String, isBusy: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Button(title, action: action)
                .disabled(isBusy)

            if isBusy {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func openURLButton(_ title: String, url: URL) -> some View {
        Button(title) {
            NSWorkspace.shared.open(url)
        }
    }

    private func showError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        isAlertVisible = true
    }

    private func refreshModels() {
        isRefreshingModels = true

        Task {
            do {
                try await viewModel.refreshAvailableModels()
            } catch {
                showError(title: AppText.errorTitle(viewModel.interfaceLanguage), message: error.localizedDescription)
            }

            isRefreshingModels = false
        }
    }

    private func checkForUpdate() {
        isCheckingUpdate = true

        Task {
            do {
                let endpoint = URL(
                    string: "https://api.github.com/repos/boundlessend/translate-go/releases/latest"
                )!
                let checker = UpdateChecker(releasesEndpoint: endpoint)
                updateResult = try await checker.checkForUpdate(currentVersion: currentVersion)
            } catch {
                showError(title: AppText.errorTitle(viewModel.interfaceLanguage), message: error.localizedDescription)
            }

            isCheckingUpdate = false
        }
    }

    private func handleHotkeyRecord(_ result: Result<HotkeyConfiguration, Error>) {
        do {
            let configuration = try result.get()
            try viewModel.updateHotkey(configuration)
            isRecordingHotkey = false
        } catch {
            showError(
                title: AppText.hotkeyErrorTitle(viewModel.interfaceLanguage),
                message: error.localizedDescription
            )
        }
    }

    private func resetHotkey() {
        viewModel.resetHotkey()
        isRecordingHotkey = false
    }
}
