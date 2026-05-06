import Foundation

enum AppText {
    static func currentLanguage() -> AppLanguage {
        AppLanguage.current(userDefaults: .standard)
    }

    static func settingsTitle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Настройки"
        case .english:
            return "Settings"
        }
    }

    static func settingsMenuTitle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Настройки..."
        case .english:
            return "Settings..."
        }
    }

    static func quitTitle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Выйти из translate&go"
        case .english:
            return "Quit translate&go"
        }
    }

    static func modelLabel(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Модель"
        case .english:
            return "Model"
        }
    }

    static func refreshModelsButton(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Обновить модели"
        case .english:
            return "Refresh models"
        }
    }

    static func downloadModelButton(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Скачать модель"
        case .english:
            return "Download model"
        }
    }

    static func targetLanguagePlaceholder(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Язык перевода"
        case .english:
            return "Target language"
        }
    }

    static func interfaceLanguageLabel(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Язык интерфейса"
        case .english:
            return "Interface language"
        }
    }

    static func hotkeyLabel(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Хоткей"
        case .english:
            return "Hotkey"
        }
    }

    static func pressShortcutButton(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Нажмите сочетание"
        case .english:
            return "Press shortcut"
        }
    }

    static func changeButton(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Изменить"
        case .english:
            return "Change"
        }
    }

    static func resetButton(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Сброс"
        case .english:
            return "Reset"
        }
    }

    static func cancelButton(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Отмена"
        case .english:
            return "Cancel"
        }
    }

    static func showDockToggle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Показывать в Dock"
        case .english:
            return "Show in Dock"
        }
    }

    static func showMenuBarToggle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Показывать в Menu Bar"
        case .english:
            return "Show in Menu Bar"
        }
    }

    static func errorTitle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "ошибка"
        case .english:
            return "error"
        }
    }

    static func hotkeyErrorTitle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "ошибка хоткея"
        case .english:
            return "hotkey error"
        }
    }

    static func welcomeMessage(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "привет! спасибо за выбор моей проги, надеюсь она будет полезна! по всем вопросам пиши @boundlessend"
        case .english:
            return "Hi! Thanks for choosing my app. I hope it helps. For questions, write to @boundlessend."
        }
    }

    static func translationStartedTitle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Перевод начат"
        case .english:
            return "Translation started"
        }
    }

    static func translationStartedMessage(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Результат появится в буфере обмена после готовности."
        case .english:
            return "The result will be written to the pasteboard when ready."
        }
    }

    static func translationReadyTitle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Перевод готов"
        case .english:
            return "Translation ready"
        }
    }

    static func translationReadyMessage(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Текст записан в буфер обмена."
        case .english:
            return "Text has been written to the pasteboard."
        }
    }

    static func translationErrorTitle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Ошибка перевода"
        case .english:
            return "Translation error"
        }
    }

    static func logLabel(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Лог"
        case .english:
            return "Log"
        }
    }

    static func statusItemDescription(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Перевод"
        case .english:
            return "Translation"
        }
    }

    static func accessibilityPermissionTitle(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Нужно разрешение Accessibility"
        case .english:
            return "Accessibility permission required"
        }
    }

    static func accessibilityPermissionMessage(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return """
            Откройте System Settings → Privacy & Security → Accessibility и включите translate&go.

            Если приложение уже есть в списке, удалите старую запись, добавьте заново файл:
            /Applications/translate&go.app

            После этого перезапустите приложение через run_app.command.
            """
        case .english:
            return """
            Open System Settings → Privacy & Security → Accessibility and enable translate&go.

            If the app is already in the list, remove the old entry and add this file again:
            /Applications/translate&go.app

            After that, restart the app with run_app.command.
            """
        }
    }

    static func openSettingsButton(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Открыть настройки"
        case .english:
            return "Open Settings"
        }
    }

    static func laterButton(_ language: AppLanguage) -> String {
        switch language {
        case .russian:
            return "Позже"
        case .english:
            return "Later"
        }
    }
}
