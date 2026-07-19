import XCTest

@testable import OllamaTranslatorApp

final class DiagnosticLoggerSmokeTests: XCTestCase {
    /// проверяет реальную запись: каталог и файл создаются, строка структурирована, кавычки экранированы
    func testLoggerWritesStructuredLineToLogFile() {
        let logger = DiagnosticLogger()
        let marker = "logger_smoke_\(UInt64(Date().timeIntervalSince1970 * 1_000))"
        logger.log(event: marker, fields: ["check": "value with \"quotes\""])

        let logURL = URL(fileURLWithPath: logger.logURLPath())
        let deadline = Date().addingTimeInterval(2)
        var contents = ""
        while Date() < deadline {
            contents = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
            if contents.contains(marker) {
                break
            }

            Thread.sleep(forTimeInterval: 0.05)
        }

        XCTAssertTrue(
            contents.contains("event=\(marker) check=\"value with \\\"quotes\\\"\""),
            "log line with event \(marker) not found in \(logger.logURLPath())"
        )
    }
}
