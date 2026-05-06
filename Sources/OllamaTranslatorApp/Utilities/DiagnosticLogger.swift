import Foundation

struct DiagnosticLogger {
    private let logURL: URL

    init() {
        let directoryURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("translate-go")

        try? FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        self.logURL = directoryURL.appendingPathComponent("translator.log")
    }

    func log(event: String, fields: [String: String]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let formattedFields = fields
            .map { key, value in "\(key)=\(escaped(value))" }
            .sorted()
            .joined(separator: " ")
        let line = "\(timestamp) event=\(event) \(formattedFields)\n"

        guard let data = line.data(using: .utf8) else {
            return
        }

        if FileManager.default.fileExists(atPath: logURL.path) == false {
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
        }

        guard let fileHandle = try? FileHandle(forWritingTo: logURL) else {
            return
        }

        defer {
            try? fileHandle.close()
        }

        _ = try? fileHandle.seekToEnd()
        _ = try? fileHandle.write(contentsOf: data)
    }

    func logURLPath() -> String {
        logURL.path
    }

    private func escaped(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
    }
}
