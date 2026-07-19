import Foundation

/// находит исполняемый файл ollama: сначала путь из настроек, затем стандартные места установки
enum OllamaExecutable {
    static let candidatePaths: [String] = [
        "/opt/homebrew/bin/ollama",
        "/usr/local/bin/ollama",
    ]

    static func resolvedPath(preferredPath: String?) -> String? {
        if let preferredPath, preferredPath.isEmpty == false {
            return FileManager.default.isExecutableFile(atPath: preferredPath) ? preferredPath : nil
        }

        return candidatePaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func missingPathDescription(preferredPath: String?) -> String {
        if let preferredPath, preferredPath.isEmpty == false {
            return preferredPath
        }

        return candidatePaths.joined(separator: ", ")
    }
}
