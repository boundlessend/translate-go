import SwiftUI

struct QAView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        let language = viewModel.interfaceLanguage

        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 3) {
                    Text("translate&go Q&A")
                        .font(.title2.weight(.semibold))
                    Text(subtitle(language))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(items(language)) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.question)
                                .font(.headline)
                            Text(item.answer)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            Text("© boundlessend")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(22)
        .frame(width: 560, height: 520)
    }

    private func subtitle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Быстрая помощь по настройке и частым проблемам"
        case .english:
            return "Quick help for setup and common issues"
        }
    }

    private func items(_ language: AppLanguage) -> [QAItem] {
        switch language {
        case .russian:
            return [
                QAItem(
                    question: "Как выполнить первую настройку?",
                    answer: "Откройте Settings. В поле 'Модель' выберите установленную модель из списка. Если список пустой, нажмите 'Скачать модель', найдите модель на сайте, установите её через Terminal командой `ollama pull название:тег`, затем вернитесь в Settings и нажмите 'Обновить модели'. После этого укажите Target language и задайте хоткей."
                ),
                QAItem(
                    question: "Как понять, какую модель выбрать?",
                    answer: "Для перевода лучше выбирать модель, которая уже скачана локально и отображается в списке моделей. Если нужна конкретная модель, скачайте её заранее через `ollama pull`, затем обновите список в Settings."
                ),
                QAItem(
                    question: "Что делать, если не копируется выделенный текст?",
                    answer: "Проверьте System Settings -> Privacy & Security -> Accessibility. В списке должен быть включён /Applications/translate&go.app. Если там старая запись, удалите её и добавьте приложение заново."
                ),
                QAItem(
                    question: "Почему модель не появляется в списке?",
                    answer: "Проверьте, что установлен CLI `/usr/local/bin/ollama` и команда `ollama list` показывает модель. Если модель только что скачана, нажмите 'Обновить модели' в Settings."
                ),
                QAItem(
                    question: "Что происходит после нажатия хоткея?",
                    answer: "Приложение копирует выделенный текст, отправляет его на локальный перевод и записывает результат в системный буфер обмена только после готовности. Если нажать хоткей ещё раз, предыдущая задача отменится и начнётся перевод нового выделения."
                ),
                QAItem(
                    question: "Что делать, если перевод не появляется в буфере?",
                    answer: "Проверьте, что модель выбрана, локальный сервер доступен, выделение не пустое, а в Accessibility включён именно файл /Applications/translate&go.app. Подробная ошибка показывается в окне приложения и пишется в лог."
                )
            ]
        case .english:
            return [
                QAItem(
                    question: "How do I set up the app for the first time?",
                    answer: "Open Settings. In Model, choose an installed model. If the list is empty, click Download model, find a model on the website, install it in Terminal with `ollama pull model:tag`, then return to Settings and click Refresh models. After that, set Target language and choose a hotkey."
                ),
                QAItem(
                    question: "Which model should I choose?",
                    answer: "For translation, choose a model that is already downloaded locally and appears in the model list. If you need a specific model, download it first with `ollama pull`, then refresh the list in Settings."
                ),
                QAItem(
                    question: "What if selected text is not copied?",
                    answer: "Check System Settings -> Privacy & Security -> Accessibility. /Applications/translate&go.app must be enabled. If an old entry exists, remove it and add the app again."
                ),
                QAItem(
                    question: "Why is my model missing from the list?",
                    answer: "Check that `/usr/local/bin/ollama` is installed and `ollama list` shows the model. If you downloaded the model recently, click Refresh models in Settings."
                ),
                QAItem(
                    question: "What happens after pressing the hotkey?",
                    answer: "The app copies the selected text, sends it to local translation, and writes the result to the system pasteboard only when it is ready. Pressing the hotkey again cancels the previous task and starts translating the new selection."
                ),
                QAItem(
                    question: "What if translation does not appear in the pasteboard?",
                    answer: "Check that a model is selected, the local server is available, the selection is not empty, and Accessibility is enabled for /Applications/translate&go.app. Detailed errors are shown in the app and written to the log."
                )
            ]
        }
    }
}

private struct QAItem: Identifiable {
    let id: UUID
    let question: String
    let answer: String

    init(question: String, answer: String) {
        self.id = UUID()
        self.question = question
        self.answer = answer
    }
}
