import Foundation

struct OllamaPreloadRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
    let keepAlive: String

    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case stream
        case keepAlive = "keep_alive"
    }
}
