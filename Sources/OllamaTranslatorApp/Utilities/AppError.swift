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
        switch AppText.currentLanguage() {
        case .russian:
            return russianDescription
        case .english:
            return englishDescription
        }
    }

    private var russianDescription: String {
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

    private var englishDescription: String {
        switch self {
        case .accessibilityPermissionMissing:
            return "Accessibility permission is missing. Allow this app to control your computer in System Settings → Privacy & Security → Accessibility."
        case .emptyPasteboard:
            return "Selected text was not found. Select text in the active app and try again."
        case .emptyTranslation:
            return "Ollama returned an empty translation."
        case .invalidResponse:
            return "Ollama returned a response without an HTTP status."
        case .copySelectionTimedOut:
            return "Could not read selected text with Command-C. Check the text selection and Accessibility permission."
        case .pasteboardWriteFailed:
            return "Could not write the translation to the system pasteboard."
        case .pasteboardRestoreFailed:
            return "Could not restore the previous system pasteboard after an error."
        case let .ollamaExecutableMissing(path):
            return "Ollama was not found at \(path). Install Ollama or add the binary to this path."
        case .ollamaStartupTimedOut:
            return "Ollama did not start in time."
        case .hotkeyRequiresModifier:
            return "The hotkey must include at least one modifier: Control, Option, Shift, or Command."
        case .hotkeyInvalidKey:
            return "Press a regular key together with a modifier."
        case let .hotkeyReservedBySystem(hotkey):
            return "Hotkey \(hotkey) is already used by macOS or the app menu. Choose another shortcut."
        case let .hotkeyRegistrationFailed(hotkey):
            return "Hotkey \(hotkey) is already used by another app. Choose another shortcut."
        case let .ollamaCommandFailed(command, statusCode, output):
            return "Command \(command) exited with code \(statusCode). Output: \(output)"
        case let .ollamaHTTPError(statusCode, body):
            return "Ollama returned HTTP \(statusCode). Response body: \(body)"
        case let .networkUnavailable(error):
            return "Network request failed. Error: \(error.localizedDescription)"
        case let .decodingFailed(error):
            return "Could not parse translator JSON response. Error: \(error.localizedDescription)"
        case let .unexpected(error):
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
}
