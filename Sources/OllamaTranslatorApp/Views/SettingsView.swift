import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var isRefreshingModels = false
    @State private var isRecordingHotkey = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isAlertVisible = false

    var body: some View {
        Form {
            Section {
                Picker("Модель", selection: $viewModel.model) {
                    ForEach(viewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .onChange(of: viewModel.model) { selectedModel in
                    viewModel.selectModel(selectedModel)
                }

                HStack {
                    Button("Обновить модели") {
                        refreshModels()
                    }
                    .disabled(isRefreshingModels)

                    Button("Скачать модель") {
                        openModelSearch()
                    }
                }

                TextField("Target language", text: $viewModel.targetLanguageText)
                    .textFieldStyle(.roundedBorder)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Хоткей")
                        .font(.headline)

                    HStack {
                        Text(viewModel.hotkeyConfiguration.title)
                            .font(.system(.title3, design: .monospaced))
                            .frame(width: 90, alignment: .leading)

                        Button(isRecordingHotkey ? "Нажмите сочетание" : "Изменить") {
                            isRecordingHotkey = true
                        }

                        Button("Сброс") {
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

                            Button("Отмена") {
                                isRecordingHotkey = false
                            }
                        }
                    }
                }

                Toggle("Показывать в Dock", isOn: $viewModel.isDockVisible)
                Toggle("Показывать в Menu Bar", isOn: $viewModel.isMenuBarVisible)
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
                alertTitle = "ошибка"
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
            alertTitle = "ошибка хоткея"
            alertMessage = error.localizedDescription
            isAlertVisible = true
        }
    }

    private func resetHotkey() {
        viewModel.resetHotkey()
        isRecordingHotkey = false
    }
}
