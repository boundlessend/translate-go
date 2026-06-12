import Foundation

/// пишет структурированные события в пользовательский лог приложения
struct DiagnosticLogger {
    private let logURL: URL

    init() {
        let directoryURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("translate-go")

        self.logURL = directoryURL.appendingPathComponent("translator.log")

        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            writeFallback(message: "event=log_directory_create_failed error=\(escaped(error.localizedDescription))")
        }
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

        let fileHandle: FileHandle
        do {
            fileHandle = try FileHandle(forWritingTo: logURL)
        } catch {
            writeFallback(message: "event=log_file_open_failed error=\(escaped(error.localizedDescription))")
            return
        }

        defer {
            do {
                try fileHandle.close()
            } catch {
                writeFallback(message: "event=log_file_close_failed error=\(escaped(error.localizedDescription))")
            }
        }

        do {
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: data)
        } catch {
            writeFallback(message: "event=log_file_write_failed error=\(escaped(error.localizedDescription))")
        }
    }

    func logURLPath() -> String {
        logURL.path
    }

    private func escaped(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    private func writeFallback(message: String) {
        let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
        guard let data = line.data(using: .utf8) else {
            return
        }

        FileHandle.standardError.write(data)
    }
}
