import Foundation

enum OllamaModelPreset: String, CaseIterable, Identifiable {
    case translateGemma12b = "translategemma:12b"

    var id: String {
        rawValue
    }
}
