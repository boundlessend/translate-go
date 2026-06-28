import Foundation

/// находит исполняемый файл ollama в стандартных местах установки
enum OllamaExecutable {
    static let candidatePaths: [String] = [
        "/opt/homebrew/bin/ollama",
        "/usr/local/bin/ollama",
    ]

    static func resolvedPath() -> String? {
        candidatePaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}
