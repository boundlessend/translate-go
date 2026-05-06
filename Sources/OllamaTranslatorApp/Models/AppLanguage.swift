import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case russian
    case english

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .russian:
            return "Русский"
        case .english:
            return "English"
        }
    }

    static func current(userDefaults: UserDefaults) -> AppLanguage {
        let storedValue = userDefaults.string(forKey: AppLanguageDefaultsKey.interfaceLanguage)
        return storedValue.flatMap(AppLanguage.init(rawValue:)) ?? .english
    }
}

enum AppLanguageDefaultsKey {
    static let interfaceLanguage: String = "interfaceLanguage"
}
