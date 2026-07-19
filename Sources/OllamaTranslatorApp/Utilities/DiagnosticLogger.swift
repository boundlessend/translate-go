import Foundation

/// пишет структурированные события в пользовательский лог приложения, сериализуя записи
/// @unchecked: все поля неизменяемые, запись в файл сериализована через queue
final class DiagnosticLogger: @unchecked Sendable {
    private let logURL: URL
    private let queue: DispatchQueue
    private let timestampFormatter: ISO8601DateFormatter
    private let maxLogSizeBytes: UInt64 = 5 * 1024 * 1024

    init() {
        let directoryURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("translate-go")

        self.logURL = directoryURL.appendingPathComponent("translator.log")
        self.queue = DispatchQueue(label: "dev.boundlessend.translate-go.diagnostic-logger")
        self.timestampFormatter = ISO8601DateFormatter()

        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            writeFallback(message: "event=log_directory_create_failed error=\(escaped(error.localizedDescription))")
        }

        rotateOversizedLog()
    }

    func log(event: String, fields: [String: String]) {
        let timestamp = timestampFormatter.string(from: Date())
        let formattedFields =
            fields
            .map { key, value in "\(key)=\(escaped(value))" }
            .sorted()
            .joined(separator: " ")
        let line = "\(timestamp) event=\(event) \(formattedFields)\n"

        queue.async {
            self.writeLine(line)
        }
    }

    func logURLPath() -> String {
        logURL.path
    }

    /// ponytail: вместо ротации файл просто удаляется при старте, история старше одного запуска не нужна
    private func rotateOversizedLog() {
        let attributes = try? FileManager.default.attributesOfItem(atPath: logURL.path)
        guard let size = attributes?[.size] as? UInt64, size > maxLogSizeBytes else {
            return
        }

        do {
            try FileManager.default.removeItem(at: logURL)
        } catch {
            writeFallback(message: "event=log_rotation_failed error=\(escaped(error.localizedDescription))")
        }
    }

    private func writeLine(_ line: String) {
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

    private func escaped(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    private func writeFallback(message: String) {
        let line = "\(timestampFormatter.string(from: Date())) \(message)\n"
        guard let data = line.data(using: .utf8) else {
            return
        }

        FileHandle.standardError.write(data)
    }
}
