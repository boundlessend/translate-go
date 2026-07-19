import Foundation

/// сверяет текущую версию приложения с последним релизом на github
struct UpdateChecker {
    private let releasesEndpoint: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(releasesEndpoint: URL) {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30

        self.releasesEndpoint = releasesEndpoint
        self.session = URLSession(configuration: configuration)
        self.decoder = JSONDecoder()
    }

    func checkForUpdate(currentVersion: String) async throws -> UpdateCheckResult {
        var request = URLRequest(url: releasesEndpoint)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
                throw AppError.githubHTTPError(statusCode: httpResponse.statusCode, body: body)
            }

            let release = try decoder.decode(GitHubRelease.self, from: data)
            let latestVersion = normalizeVersion(release.tagName)

            return UpdateCheckResult(
                currentVersion: currentVersion,
                latestVersion: latestVersion,
                isUpdateAvailable: isVersion(currentVersion, olderThan: latestVersion),
                releaseURL: release.htmlURL
            )
        } catch let error as AppError {
            throw error
        } catch let error as URLError {
            throw AppError.networkUnavailable(error)
        } catch let error as DecodingError {
            throw AppError.decodingFailed(error)
        } catch {
            throw AppError.unexpected(error)
        }
    }

    /// убирает префикс тега "v." как это делает release workflow
    func normalizeVersion(_ tag: String) -> String {
        var version = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if version.hasPrefix("v") {
            version.removeFirst()
        }
        if version.hasPrefix(".") {
            version.removeFirst()
        }
        return version
    }

    /// сравнивает версии вида "1.5.5" покомпонентно, недостающие компоненты считает нулями
    func isVersion(_ lhs: String, olderThan rhs: String) -> Bool {
        let lhsParts = versionComponents(lhs)
        let rhsParts = versionComponents(rhs)
        let count = max(lhsParts.count, rhsParts.count)

        for index in 0..<count {
            let left = index < lhsParts.count ? lhsParts[index] : 0
            let right = index < rhsParts.count ? rhsParts[index] : 0
            if left != right {
                return left < right
            }
        }

        return false
    }

    private func versionComponents(_ version: String) -> [Int] {
        version.split(separator: ".").map { Int($0) ?? 0 }
    }
}
