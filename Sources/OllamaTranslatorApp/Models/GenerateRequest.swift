import Foundation

struct GenerateRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
    let options: GenerateOptions
}

struct GenerateOptions: Encodable {
    let numCtx: Int

    enum CodingKeys: String, CodingKey {
        case numCtx = "num_ctx"
    }
}
