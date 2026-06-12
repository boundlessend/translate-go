import Foundation

struct GenerateRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
    let keepAlive: String
    let options: GenerateOptions

    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case stream
        case keepAlive = "keep_alive"
        case options
    }
}

struct GenerateOptions: Encodable {
    let numCtx: Int

    enum CodingKeys: String, CodingKey {
        case numCtx = "num_ctx"
    }
}
