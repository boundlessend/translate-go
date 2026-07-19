import Foundation

/// перечисляет установленные модели через команды ollama list и ollama ps
enum OllamaModelDiscovery {
    static func fetchModels(preferredExecutablePath: String?) throws -> [String] {
        let listModels = try runOllama(arguments: ["list"], preferredExecutablePath: preferredExecutablePath)
        let runningModels = try runOllama(arguments: ["ps"], preferredExecutablePath: preferredExecutablePath)
        let models = Set(parseModelNames(output: listModels) + parseModelNames(output: runningModels))
        let sortedModels = models.sorted { left, right in
            left.localizedStandardCompare(right) == .orderedAscending
        }

        return sortedModels
    }

    private static func runOllama(arguments: [String], preferredExecutablePath: String?) throws -> String {
        guard let executablePath = OllamaExecutable.resolvedPath(preferredPath: preferredExecutablePath) else {
            throw AppError.ollamaExecutableMissing(
                path: OllamaExecutable.missingPathDescription(preferredPath: preferredExecutablePath)
            )
        }

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()

        // читать пайпы нужно до waitUntilExit, иначе процесс блокируется при выводе больше буфера пайпа
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: outputData + errorData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw AppError.ollamaCommandFailed(
                command: "ollama \(arguments.joined(separator: " "))",
                statusCode: process.terminationStatus,
                output: output
            )
        }

        return output
    }

    private static func parseModelNames(output: String) -> [String] {
        output
            .components(separatedBy: .newlines)
            .dropFirst()
            .compactMap { line -> String? in
                let columns = line.split(separator: " ")
                guard let firstColumn = columns.first else {
                    return nil
                }

                let name = String(firstColumn).trimmingCharacters(in: .whitespacesAndNewlines)
                return name.isEmpty ? nil : name
            }
    }
}
