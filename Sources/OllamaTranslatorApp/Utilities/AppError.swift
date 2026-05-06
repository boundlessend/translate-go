import Foundation

enum AppError: LocalizedError {
    case accessibilityPermissionMissing
    case emptyPasteboard
    case emptyTranslation
    case invalidResponse
    case copySelectionTimedOut
    case pasteboardWriteFailed
    case pasteboardRestoreFailed
    case ollamaExecutableMissing(path: String)
    case ollamaStartupTimedOut
    case hotkeyRequiresModifier
    case hotkeyInvalidKey
    case hotkeyReservedBySystem(hotkey: String)
    case hotkeyRegistrationFailed(hotkey: String)
    case ollamaCommandFailed(command: String, statusCode: Int32, output: String)
    case ollamaHTTPError(statusCode: Int, body: String)
    case networkUnavailable(URLError)
    case decodingFailed(DecodingError)
    case unexpected(Error)

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionMissing:
            return "Нет разрешения Accessibility. Разрешите приложению управление компьютером в System Settings → Privacy & Security → Accessibility."
        case .emptyPasteboard:
            return "Выделенный текст не найден. Выделите текст в активном приложении и повторите."
        case .emptyTranslation:
            return "Ollama вернула пустой перевод."
        case .invalidResponse:
            return "Ollama вернула ответ без HTTP-статуса."
        case .copySelectionTimedOut:
            return "Не удалось получить выделенный текст через Command-C. Проверьте выделение текста и разрешение Accessibility."
        case .pasteboardWriteFailed:
            return "Не удалось записать перевод в системный буфер обмена."
        case .pasteboardRestoreFailed:
            return "Не удалось восстановить предыдущий системный буфер обмена после ошибки."
        case let .ollamaExecutableMissing(path):
            return "Ollama не найден по пути \(path). Установите Ollama или добавьте бинарь в этот путь."
        case .ollamaStartupTimedOut:
            return "Ollama не запустилась за отведённое время."
        case .hotkeyRequiresModifier:
            return "Хоткей должен содержать хотя бы один модификатор: Control, Option, Shift или Command."
        case .hotkeyInvalidKey:
            return "Нажмите обычную клавишу вместе с модификатором."
        case let .hotkeyReservedBySystem(hotkey):
            return "Хоткей \(hotkey) уже используется macOS или меню приложения. Выберите другое сочетание."
        case let .hotkeyRegistrationFailed(hotkey):
            return "Хоткей \(hotkey) уже используется другой программой. Выберите другое сочетание."
        case let .ollamaCommandFailed(command, statusCode, output):
            return "Команда \(command) завершилась с кодом \(statusCode). Ответ: \(output)"
        case let .ollamaHTTPError(statusCode, body):
            return "Ollama вернула HTTP \(statusCode). Тело ответа: \(body)"
        case let .networkUnavailable(error):
            return "Не удалось выполнить сетевой запрос. Ошибка: \(error.localizedDescription)"
        case let .decodingFailed(error):
            return "Не удалось разобрать JSON ответа переводчика. Ошибка: \(error.localizedDescription)"
        case let .unexpected(error):
            return "Неожиданная ошибка: \(error.localizedDescription)"
        }
    }
}
