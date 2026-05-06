import AppKit
import Foundation

final class OllamaRuntimeManager {
    private let tagsEndpoint: URL
    private let generateEndpoint: URL
    private let model: String
    private let session: URLSession
    private let encoder: JSONEncoder
    private let diagnosticLogger: DiagnosticLogger
    private var process: Process?

    init(tagsEndpoint: URL, generateEndpoint: URL, model: String, diagnosticLogger: DiagnosticLogger) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60

        self.tagsEndpoint = tagsEndpoint
        self.generateEndpoint = generateEndpoint
        self.model = model
        self.session = URLSession(configuration: configuration)
        self.encoder = JSONEncoder()
        self.diagnosticLogger = diagnosticLogger
    }

    func startIfNeeded() async throws {
        diagnosticLogger.log(event: "ollama_start_check_started", fields: ["model": model])
        try await terminateOllamaApplicationIfRunning()

        if await isOllamaReady() == false {
            diagnosticLogger.log(event: "ollama_not_ready", fields: [:])
            try startOllamaServe()
            guard try await waitForOllama() else {
                throw AppError.ollamaStartupTimedOut
            }
        }

        try await preloadModel()
        diagnosticLogger.log(event: "ollama_preload_finished", fields: ["model": model])
    }

    func stopOnApplicationExit() {
        stopModel()
        stopOwnedServeProcess()
        stopAllOllamaProcesses()
    }   

    private func isOllamaReady() async -> Bool {
        var request = URLRequest(url: tagsEndpoint)
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

    private func startOllamaServe() throws {
        let executableURL = URL(fileURLWithPath: "/usr/local/bin/ollama")
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw AppError.ollamaExecutableMissing(path: executableURL.path)
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["serve"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        self.process = process
        diagnosticLogger.log(event: "ollama_serve_started", fields: ["path": executableURL.path])
    }

    private func terminateOllamaApplicationIfRunning() async throws {
        let applications = NSWorkspace.shared.runningApplications.filter { application in
            application.bundleURL?.path == "/Applications/Ollama.app"
        }

        for application in applications {
            let isTerminating = application.terminate()
            diagnosticLogger.log(
                event: "ollama_gui_terminate_requested",
                fields: [
                    "pid": String(application.processIdentifier),
                    "accepted": String(isTerminating)
                ]
            )
        }

        if applications.isEmpty == false {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        let remainingApplications = NSWorkspace.shared.runningApplications.filter { application in
            application.bundleURL?.path == "/Applications/Ollama.app"
        }

        for application in remainingApplications {
            let isTerminating = application.forceTerminate()
            diagnosticLogger.log(
                event: "ollama_gui_force_terminate_requested",
                fields: [
                    "pid": String(application.processIdentifier),
                    "accepted": String(isTerminating)
                ]
            )
        }

        if remainingApplications.isEmpty == false {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    private func waitForOllama() async throws -> Bool {
        let attempts: Int = 100
        let delayNanoseconds: UInt64 = 100_000_000

        for _ in 0..<attempts {
            if await isOllamaReady() {
                return true
            }

            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        return false
    }

    private func preloadModel() async throws {
        let requestBody = OllamaPreloadRequest(
            model: model,
            prompt: "",
            stream: false,
            keepAlive: "30m"
        )

        var request = URLRequest(url: generateEndpoint)
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

    private func stopModel() {
        let executableURL = URL(fileURLWithPath: "/usr/local/bin/ollama")
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            diagnosticLogger.log(event: "ollama_stop_skipped", fields: ["reason": "executable_missing"])
            return
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["stop", model]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            diagnosticLogger.log(
                event: "ollama_model_stop_finished",
                fields: [
                    "model": model,
                    "status": String(process.terminationStatus)
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

    private func stopAllOllamaProcesses() {
        runProcess(
            executablePath: "/usr/bin/pkill",
            arguments: ["-x", "ollama"],
            event: "ollama_process_kill_finished"
        )
        runProcess(
            executablePath: "/usr/bin/pkill",
            arguments: ["-f", "ollama runner"],
            event: "ollama_runner_kill_finished"
        )
    }

    private func runProcess(executablePath: String, arguments: [String], event: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            diagnosticLogger.log(
                event: event,
                fields: ["status": String(process.terminationStatus)]
            )
        } catch {
            diagnosticLogger.log(
                event: "\(event)_failed",
                fields: ["error": error.localizedDescription]
            )
        }
    }
}
