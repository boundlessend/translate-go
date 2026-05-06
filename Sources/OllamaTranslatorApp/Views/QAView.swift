import SwiftUI

struct QAView: View {
    private let items: [QAItem] = [
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

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 3) {
                    Text("translate&go Q&A")
                        .font(.title2.weight(.semibold))
                    Text("Быстрая помощь по настройке и частым проблемам")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(items) { item in
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
