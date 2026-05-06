import Foundation

final class OllamaModelDiscovery {
    private let executablePath: String

    init(executablePath: String) {
        self.executablePath = executablePath
    }

    func fetchModels() throws -> [String] {
        let listModels = try runOllama(arguments: ["list"])
        let runningModels = try runOllama(arguments: ["ps"])
        let models = Set(parseModelNames(output: listModels) + parseModelNames(output: runningModels))
        let sortedModels = models.sorted { left, right in
            left.localizedStandardCompare(right) == .orderedAscending
        }

        return sortedModels
    }

    private func runOllama(arguments: [String]) throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
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

    private func parseModelNames(output: String) -> [String] {
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
