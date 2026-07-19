import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var model: String {
        didSet {
            userDefaults.set(model, forKey: UserDefaultsKey.model)
        }
    }

    @Published var availableModels: [String]

    @Published var targetLanguageText: String {
        didSet {
            userDefaults.set(targetLanguageText, forKey: UserDefaultsKey.targetLanguageText)
        }
    }

    @Published var interfaceLanguage: AppLanguage {
        didSet {
            userDefaults.set(interfaceLanguage.rawValue, forKey: AppLanguageDefaultsKey.interfaceLanguage)
        }
    }

    @Published var hotkeyConfiguration: HotkeyConfiguration {
        didSet {
            userDefaults.set(hotkeyConfiguration.encode(), forKey: UserDefaultsKey.hotkeyConfiguration)
        }
    }

    @Published var isDockVisible: Bool {
        didSet {
            userDefaults.set(isDockVisible, forKey: UserDefaultsKey.isDockVisible)
        }
    }

    @Published var isMenuBarVisible: Bool {
        didSet {
            userDefaults.set(isMenuBarVisible, forKey: UserDefaultsKey.isMenuBarVisible)
        }
    }

    @Published var ollamaBaseURLText: String {
        didSet {
            userDefaults.set(ollamaBaseURLText, forKey: UserDefaultsKey.ollamaBaseURLText)
        }
    }

    @Published var ollamaExecutablePathText: String {
        didSet {
            userDefaults.set(ollamaExecutablePathText, forKey: UserDefaultsKey.ollamaExecutablePathText)
        }
    }

    @Published var isModelPreloadEnabled: Bool {
        didSet {
            userDefaults.set(isModelPreloadEnabled, forKey: UserDefaultsKey.isModelPreloadEnabled)
        }
    }

    /// текущая модель всегда присутствует в списке, чтобы picker не показывал пустое значение
    var modelOptions: [String] {
        availableModels.contains(model) ? availableModels : [model] + availableModels
    }

    var trimmedOllamaExecutablePath: String? {
        let path = ollamaExecutablePathText.trimmingCharacters(in: .whitespacesAndNewlines)
        return path.isEmpty ? nil : path
    }

    private let userDefaults: UserDefaults
    private let hotkeyValidator: HotkeyValidator

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.hotkeyValidator = HotkeyValidator()

        let storedModel = userDefaults.string(forKey: UserDefaultsKey.model)
        let normalizedModel =
            storedModel?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? OllamaDefaults.model
        self.model = normalizedModel
        self.availableModels = []
        userDefaults.set(normalizedModel, forKey: UserDefaultsKey.model)

        let storedTargetLanguageText = userDefaults.string(forKey: UserDefaultsKey.targetLanguageText)
        self.targetLanguageText = storedTargetLanguageText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Русский"
        self.interfaceLanguage = AppLanguage.current(userDefaults: userDefaults)

        let storedHotkeyData = userDefaults.data(forKey: UserDefaultsKey.hotkeyConfiguration)
        self.hotkeyConfiguration =
            storedHotkeyData.flatMap(HotkeyConfiguration.decode(data:))
            ?? HotkeyConfiguration.defaultHotkey()

        self.isDockVisible = userDefaults.object(forKey: UserDefaultsKey.isDockVisible) as? Bool ?? true
        self.isMenuBarVisible = userDefaults.object(forKey: UserDefaultsKey.isMenuBarVisible) as? Bool ?? true

        let storedBaseURLText = userDefaults.string(forKey: UserDefaultsKey.ollamaBaseURLText)
        self.ollamaBaseURLText =
            storedBaseURLText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? OllamaDefaults.baseURLText
        self.ollamaExecutablePathText = userDefaults.string(forKey: UserDefaultsKey.ollamaExecutablePathText) ?? ""
        self.isModelPreloadEnabled =
            userDefaults.object(forKey: UserDefaultsKey.isModelPreloadEnabled) as? Bool ?? true
    }

    func ollamaBaseURL() throws -> URL {
        let text = ollamaBaseURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: text),
            let scheme = url.scheme,
            ["http", "https"].contains(scheme.lowercased()),
            url.host != nil
        else {
            throw AppError.invalidOllamaBaseURL(text: text)
        }

        return url
    }

    func refreshAvailableModels() async throws {
        let preferredExecutablePath = trimmedOllamaExecutablePath
        let models = try await Task.detached(priority: .userInitiated) {
            try OllamaModelDiscovery.fetchModels(preferredExecutablePath: preferredExecutablePath)
        }.value

        availableModels = models

        // автоподбор только пока пользователь не выбрал модель сам: явный выбор не подменяется
        if model == OllamaDefaults.model, models.isEmpty == false, models.contains(model) == false {
            model = models[0]
        }
    }

    func updateHotkey(_ candidate: HotkeyConfiguration) throws {
        try hotkeyValidator.validate(candidate: candidate, current: hotkeyConfiguration)
        hotkeyConfiguration = candidate
    }

    func resetHotkey() {
        hotkeyConfiguration = HotkeyConfiguration.defaultHotkey()
    }
}

private enum UserDefaultsKey {
    static let model: String = "model"
    static let targetLanguageText: String = "targetLanguageText"
    static let hotkeyConfiguration: String = "hotkeyConfiguration"
    static let isDockVisible: String = "isDockVisible"
    static let isMenuBarVisible: String = "showMenuBarItem"
    static let ollamaBaseURLText: String = "ollamaBaseURLText"
    static let ollamaExecutablePathText: String = "ollamaExecutablePathText"
    static let isModelPreloadEnabled: String = "isModelPreloadEnabled"
}
