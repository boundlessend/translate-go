import Foundation

struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

struct UpdateCheckResult {
    let currentVersion: String
    let latestVersion: String
    let isUpdateAvailable: Bool
    let releaseURL: URL
}
