import XCTest

@testable import OllamaTranslatorApp

final class PureFunctionTests: XCTestCase {
    private let updateChecker = UpdateChecker(
        releasesEndpoint: URL(string: "https://api.github.com/repos/boundlessend/translate-go/releases/latest")!
    )
    private let translationService = TranslationService()

    func testVersionComparison() {
        XCTAssertTrue(updateChecker.isVersion("1.5.5", olderThan: "1.5.6"))
        XCTAssertTrue(updateChecker.isVersion("1.5", olderThan: "1.5.1"))
        XCTAssertTrue(updateChecker.isVersion("1.9.9", olderThan: "1.10.0"))
        XCTAssertFalse(updateChecker.isVersion("1.5.5", olderThan: "1.5.5"))
        XCTAssertFalse(updateChecker.isVersion("1.10.0", olderThan: "1.9.9"))
        XCTAssertFalse(updateChecker.isVersion("2.0.0", olderThan: "1.99.99"))
    }

    func testVersionNormalization() {
        XCTAssertEqual(updateChecker.normalizeVersion("v1.2.3"), "1.2.3")
        XCTAssertEqual(updateChecker.normalizeVersion("v.1.2.3"), "1.2.3")
        XCTAssertEqual(updateChecker.normalizeVersion("1.2.3"), "1.2.3")
        XCTAssertEqual(updateChecker.normalizeVersion(" v1.2.3 "), "1.2.3")
    }

    func testCleanTranslationDropsLeadingChatterLine() {
        let raw = "Here is the translation:\nПривет, мир"
        XCTAssertEqual(translationService.cleanTranslation(raw), "Привет, мир")
    }

    func testCleanTranslationKeepsTextStartingWithChatterWord() {
        let raw = "Here we go again, said the driver."
        XCTAssertEqual(translationService.cleanTranslation(raw), raw)
    }

    func testCleanTranslationKeepsBulletsAndBold() {
        let raw = "* первый пункт\n* второй пункт\n**важно**"
        XCTAssertEqual(translationService.cleanTranslation(raw), raw)
    }

    func testShortTextStaysSingleChunk() {
        let chunks = translationService.makeTextChunks(text: "  короткий текст  ", maxLength: 3_000)
        XCTAssertEqual(chunks, ["короткий текст"])
    }

    func testLongTextSplitsIntoBoundedChunksWithoutLosingParagraphs() {
        let paragraphs = (1...40).map { index in
            "Абзац номер \(index). " + String(repeating: "слово ", count: 30)
        }
        let text = paragraphs.joined(separator: "\n\n")
        let maxLength = 500

        let chunks = translationService.makeTextChunks(text: text, maxLength: maxLength)

        XCTAssertGreaterThan(chunks.count, 1)
        for chunk in chunks {
            XCTAssertLessThanOrEqual(chunk.count, maxLength)
        }
        for index in 1...40 {
            XCTAssertTrue(chunks.joined(separator: "\n\n").contains("Абзац номер \(index)."))
        }
    }

    func testOversizedParagraphSplitsBySentences() {
        let paragraph = (1...30).map { "Предложение номер \($0)" }.joined(separator: ". ")
        let chunks = translationService.splitLongParagraph(paragraph, maxLength: 200)

        XCTAssertGreaterThan(chunks.count, 1)
        for chunk in chunks {
            XCTAssertLessThanOrEqual(chunk.count, 200)
        }
        let joined = chunks.joined(separator: " ")
        for index in 1...30 {
            XCTAssertTrue(joined.contains("Предложение номер \(index)."))
        }
    }
}
