import Foundation

struct TranslationService {
    private let ollamaEndpoint: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(ollamaEndpoint: URL) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 600
        configuration.timeoutIntervalForResource = 600

        self.ollamaEndpoint = ollamaEndpoint
        self.session = URLSession(configuration: configuration)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func translate(
        text: String,
        model: String,
        targetLanguage: String
    ) async throws -> String {
        try await translateWithOllama(text: text, model: model, targetLanguage: targetLanguage)
    }

    private func translateWithOllama(text: String, model: String, targetLanguage: String) async throws -> String {
        let chunks: [String] = makeTextChunks(text: text, maxLength: 3_000)
        var translatedChunks: [String] = []

        for chunk in chunks {
            try Task.checkCancellation()
            let translatedChunk = try await translateOllamaChunk(text: chunk, model: model, targetLanguage: targetLanguage)
            translatedChunks.append(translatedChunk)
        }

        return translatedChunks.joined(separator: "\n\n")
    }

    private func translateOllamaChunk(text: String, model: String, targetLanguage: String) async throws -> String {
        let requestBody = GenerateRequest(
            model: model,
            prompt: makeOllamaPrompt(text: text, targetLanguage: targetLanguage),
            stream: false,
            options: GenerateOptions(numCtx: 8_192)
        )

        var request = URLRequest(url: ollamaEndpoint)
        request.timeoutInterval = 600
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(requestBody)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                throw AppError.ollamaHTTPError(statusCode: httpResponse.statusCode, body: body)
            }

            let generateResponse = try decoder.decode(GenerateResponse.self, from: data)
            let translatedText = cleanTranslation(generateResponse.response)
            guard translatedText.isEmpty == false else {
                throw AppError.emptyTranslation
            }

            return translatedText
        } catch let error as AppError {
            throw error
        } catch let error as URLError {
            guard error.code != .cancelled else {
                throw CancellationError()
            }

            throw AppError.networkUnavailable(error)
        } catch let error as DecodingError {
            throw AppError.decodingFailed(error)
        } catch {
            throw AppError.unexpected(error)
        }
    }

    private func makeOllamaPrompt(text: String, targetLanguage: String) -> String {
        """
        You are a translation engine.
        Translate the text to \(targetLanguage).
        Translate the entire text.
        Preserve all paragraphs and line breaks.
        Return only the single best translation.
        Do not explain.
        Do not provide alternatives.
        Do not use Markdown.
        Do not include transliteration.
        Do not include the source text.

        Text:
        \(text)

        Output only the translated text:
        """
    }

    private func cleanTranslation(_ text: String) -> String {
        let lines = text
            .replacingOccurrences(of: "**", with: "")
            .components(separatedBy: .newlines)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                line.isEmpty
                    || line.hasPrefix("*") == false
                    && line.lowercased().hasPrefix("option") == false
                    && line.lowercased().hasPrefix("here") == false
                    && line.lowercased().hasPrefix("the best") == false
                    && line.lowercased().hasPrefix("explanation") == false
            }

        guard lines.isEmpty == false else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeTextChunks(text: String, maxLength: Int) -> [String] {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedText.count > maxLength else {
            return [normalizedText]
        }

        let paragraphs: [String] = normalizedText
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        var chunks: [String] = []
        var currentChunk = ""

        for paragraph in paragraphs {
            let candidate = currentChunk.isEmpty ? paragraph : "\(currentChunk)\n\n\(paragraph)"

            if candidate.count <= maxLength {
                currentChunk = candidate
                continue
            }

            if currentChunk.isEmpty == false {
                chunks.append(currentChunk)
            }

            if paragraph.count <= maxLength {
                currentChunk = paragraph
            } else {
                chunks.append(contentsOf: splitLongParagraph(paragraph, maxLength: maxLength))
                currentChunk = ""
            }
        }

        if currentChunk.isEmpty == false {
            chunks.append(currentChunk)
        }

        return chunks
    }

    private func splitLongParagraph(_ paragraph: String, maxLength: Int) -> [String] {
        let sentences: [String] = paragraph
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        var chunks: [String] = []
        var currentChunk = ""

        for sentence in sentences {
            let normalizedSentence = sentence.hasSuffix(".") ? sentence : "\(sentence)."
            let candidate = currentChunk.isEmpty ? normalizedSentence : "\(currentChunk) \(normalizedSentence)"

            if candidate.count <= maxLength {
                currentChunk = candidate
            } else {
                if currentChunk.isEmpty == false {
                    chunks.append(currentChunk)
                }
                currentChunk = normalizedSentence
            }
        }

        if currentChunk.isEmpty == false {
            chunks.append(currentChunk)
        }

        return chunks
    }

}
