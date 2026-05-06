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

    private let userDefaults: UserDefaults
    private let modelDiscovery: OllamaModelDiscovery
    private let hotkeyValidator: HotkeyValidator

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.modelDiscovery = OllamaModelDiscovery(executablePath: "/usr/local/bin/ollama")
        self.hotkeyValidator = HotkeyValidator()

        let storedModel = userDefaults.string(forKey: UserDefaultsKey.model)
        let normalizedModel = storedModel?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? OllamaModelPreset.translateGemma12b.rawValue
        self.model = normalizedModel
        self.availableModels = []
        userDefaults.set(normalizedModel, forKey: UserDefaultsKey.model)

        let storedTargetLanguageText = userDefaults.string(forKey: UserDefaultsKey.targetLanguageText)
        self.targetLanguageText = storedTargetLanguageText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Русский"
        self.interfaceLanguage = AppLanguage.current(userDefaults: userDefaults)

        let storedHotkeyData = userDefaults.data(forKey: UserDefaultsKey.hotkeyConfiguration)
        self.hotkeyConfiguration = storedHotkeyData.flatMap(HotkeyConfiguration.decode(data:))
            ?? HotkeyConfiguration.controlC()

        self.isDockVisible = userDefaults.object(forKey: UserDefaultsKey.isDockVisible) as? Bool ?? true
        self.isMenuBarVisible = userDefaults.object(forKey: UserDefaultsKey.isMenuBarVisible) as? Bool ?? true
    }

    func refreshAvailableModels() async throws {
        let models = try await Task.detached(priority: .userInitiated) { [modelDiscovery] in
            try modelDiscovery.fetchModels()
        }.value

        availableModels = models

        guard models.isEmpty == false else {
            return
        }

        guard models.contains(model) else {
            model = models[0]
            return
        }
    }

    func selectModel(_ selectedModel: String) {
        guard selectedModel.isEmpty == false else {
            return
        }

        model = selectedModel
    }

    func updateHotkey(_ candidate: HotkeyConfiguration) throws {
        try hotkeyValidator.validate(candidate: candidate, current: hotkeyConfiguration)
        hotkeyConfiguration = candidate
    }

    func resetHotkey() {
        hotkeyConfiguration = HotkeyConfiguration.controlC()
    }
}

private enum UserDefaultsKey {
    static let model: String = "model"
    static let targetLanguageText: String = "targetLanguageText"
    static let hotkeyConfiguration: String = "hotkeyConfiguration"
    static let isDockVisible: String = "isDockVisible"
    static let isMenuBarVisible: String = "showMenuBarItem"
}
