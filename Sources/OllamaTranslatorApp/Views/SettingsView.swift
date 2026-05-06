import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var isRefreshingModels = false
    @State private var isRecordingHotkey = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isAlertVisible = false

    var body: some View {
        let language = viewModel.interfaceLanguage

        Form {
            Section {
                Picker(AppText.modelLabel(language), selection: $viewModel.model) {
                    ForEach(viewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .onChange(of: viewModel.model) { selectedModel in
                    viewModel.selectModel(selectedModel)
                }

                HStack {
                    Button(AppText.refreshModelsButton(language)) {
                        refreshModels()
                    }
                    .disabled(isRefreshingModels)

                    Button(AppText.downloadModelButton(language)) {
                        openModelSearch()
                    }
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
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.hotkeyLabel(language))
                        .font(.headline)

                    HStack {
                        Text(viewModel.hotkeyConfiguration.title)
                            .font(.system(.title3, design: .monospaced))
                            .frame(width: 90, alignment: .leading)

                        Button(isRecordingHotkey ? AppText.pressShortcutButton(language) : AppText.changeButton(language)) {
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

    private func refreshModels() {
        isRefreshingModels = true

        Task {
            do {
                try await viewModel.refreshAvailableModels()
            } catch {
                alertTitle = AppText.errorTitle(viewModel.interfaceLanguage)
                alertMessage = error.localizedDescription
                isAlertVisible = true
            }

            isRefreshingModels = false
        }
    }

    private func openModelSearch() {
        let url = URL(string: "https://ollama.com/search")!
        NSWorkspace.shared.open(url)
    }

    private func handleHotkeyRecord(_ result: Result<HotkeyConfiguration, Error>) {
        do {
            let configuration = try result.get()
            try viewModel.updateHotkey(configuration)
            isRecordingHotkey = false
        } catch {
            alertTitle = AppText.hotkeyErrorTitle(viewModel.interfaceLanguage)
            alertMessage = error.localizedDescription
            isAlertVisible = true
        }
    }

    private func resetHotkey() {
        viewModel.resetHotkey()
        isRecordingHotkey = false
    }
}
