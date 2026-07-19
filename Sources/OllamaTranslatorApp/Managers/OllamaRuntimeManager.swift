import AppKit
import Foundation

/// управляет локальным сервером ollama, запущенным этим приложением
actor OllamaRuntimeManager {
    private let session: URLSession
    private let encoder: JSONEncoder
    private let diagnosticLogger: DiagnosticLogger
    private var process: Process?

    init(diagnosticLogger: DiagnosticLogger) {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 600

        self.session = URLSession(configuration: configuration)
        self.encoder = JSONEncoder()
        self.diagnosticLogger = diagnosticLogger
    }

    func startIfNeeded(
        baseURL: URL,
        preferredExecutablePath: String?,
        model: String,
        shouldPreloadModel: Bool
    ) async throws {
        diagnosticLogger.log(event: "ollama_start_check_started", fields: ["model": model])
        let tagsEndpoint = baseURL.appendingPathComponent("api/tags")

        if await isOllamaReady(tagsEndpoint: tagsEndpoint) == false {
            diagnosticLogger.log(event: "ollama_not_ready", fields: [:])
            try startOllamaServe(preferredExecutablePath: preferredExecutablePath)
            guard try await waitForOllama(tagsEndpoint: tagsEndpoint) else {
                throw AppError.ollamaStartupTimedOut
            }
        }

        guard shouldPreloadModel else {
            diagnosticLogger.log(event: "ollama_preload_skipped", fields: ["reason": "disabled_in_settings"])
            return
        }

        try await preloadModel(generateEndpoint: baseURL.appendingPathComponent("api/generate"), model: model)
        diagnosticLogger.log(event: "ollama_preload_finished", fields: ["model": model])
    }

    func stopOnApplicationExit(preferredExecutablePath: String?, model: String) {
        guard process != nil else {
            diagnosticLogger.log(event: "ollama_stop_skipped", fields: ["reason": "server_not_owned"])
            return
        }

        stopModel(preferredExecutablePath: preferredExecutablePath, model: model)
        stopOwnedServeProcess()
    }

    private func isOllamaReady(tagsEndpoint: URL) async -> Bool {
        var request = URLRequest(url: tagsEndpoint)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 2

        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }

            return (200...299).contains(httpResponse.statusCode)
        } catch {
            return false
        }
    }

    private func startOllamaServe(preferredExecutablePath: String?) throws {
        guard let executablePath = OllamaExecutable.resolvedPath(preferredPath: preferredExecutablePath) else {
            throw AppError.ollamaExecutableMissing(
                path: OllamaExecutable.missingPathDescription(preferredPath: preferredExecutablePath)
            )
        }

        let executableURL = URL(fileURLWithPath: executablePath)
        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["serve"]
        // вывод не читается, поэтому пайпы нельзя: заполненный буфер пайпа заблокировал бы сервер
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        self.process = process
        diagnosticLogger.log(event: "ollama_serve_started", fields: ["path": executableURL.path])
    }

    private func waitForOllama(tagsEndpoint: URL) async throws -> Bool {
        let attempts: Int = 100
        let delayNanoseconds: UInt64 = 100_000_000

        for _ in 0..<attempts {
            if await isOllamaReady(tagsEndpoint: tagsEndpoint) {
                return true
            }

            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        return false
    }

    private func preloadModel(generateEndpoint: URL, model: String) async throws {
        let requestBody = GenerateRequest(
            model: model,
            prompt: "",
            stream: false,
            keepAlive: "30m",
            options: nil
        )

        var request = URLRequest(url: generateEndpoint)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 600
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw AppError.ollamaHTTPError(statusCode: httpResponse.statusCode, body: body)
        }
    }

    private func stopModel(preferredExecutablePath: String?, model: String) {
        guard let executablePath = OllamaExecutable.resolvedPath(preferredPath: preferredExecutablePath) else {
            diagnosticLogger.log(event: "ollama_stop_skipped", fields: ["reason": "executable_missing"])
            return
        }

        let executableURL = URL(fileURLWithPath: executablePath)
        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["stop", model]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            diagnosticLogger.log(
                event: "ollama_model_stop_finished",
                fields: [
                    "model": model,
                    "status": String(process.terminationStatus),
                ]
            )
        } catch {
            diagnosticLogger.log(
                event: "ollama_model_stop_failed",
                fields: ["error": error.localizedDescription]
            )
        }
    }

    private func stopOwnedServeProcess() {
        guard let process else {
            diagnosticLogger.log(event: "ollama_serve_stop_skipped", fields: ["reason": "not_owned"])
            return
        }

        guard process.isRunning else {
            diagnosticLogger.log(event: "ollama_serve_stop_skipped", fields: ["reason": "not_running"])
            return
        }

        process.terminate()
        process.waitUntilExit()
        diagnosticLogger.log(event: "ollama_serve_stop_finished", fields: [:])
    }

}
