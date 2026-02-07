import Foundation

/// Response parsing helpers for GitHub API
extension GitHubOnDemandFetcher {
    func parseGitHubURL(_ url: String) throws -> ParsedGitHubURL {
        let patterns = [
            #"github\.com[:/]([^/]+)/([^/.]+)"#,
            #"github\.com/([^/]+)/([^/]+?)(?:\.git)?$"#
        ]

        for pattern in patterns {
            if let result = try? matchPattern(pattern, in: url) {
                return result
            }
        }

        throw OnDemandFetchError.invalidURL
    }

    func parseTreeResponse(_ data: Data) throws -> [GitHubTreeNodeDTO] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tree = json["tree"] as? [[String: Any]] else {
            throw OnDemandFetchError.parseError
        }

        return tree.compactMap { node -> GitHubTreeNodeDTO? in
            guard let path = node["path"] as? String,
                  let type = node["type"] as? String,
                  type == "blob" else { return nil }
            return GitHubTreeNodeDTO(path: path, size: node["size"] as? Int ?? 0)
        }
    }

    func parseContentResponse(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? String,
              let encoding = json["encoding"] as? String,
              encoding == "base64" else {
            throw OnDemandFetchError.parseError
        }

        guard let decodedData = Data(base64Encoded: content.replacingOccurrences(of: "\n", with: "")),
              let decodedString = String(data: decodedData, encoding: .utf8) else {
            throw OnDemandFetchError.decodeError
        }

        return decodedString
    }

    private func matchPattern(_ pattern: String, in url: String) throws -> ParsedGitHubURL? {
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        guard let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
              let ownerRange = Range(match.range(at: 1), in: url),
              let repoRange = Range(match.range(at: 2), in: url) else {
            return nil
        }

        let owner = String(url[ownerRange])
        var repo = String(url[repoRange])
        if repo.hasSuffix(".git") {
            repo = String(repo.dropLast(4))
        }
        return ParsedGitHubURL(owner: owner, repo: repo)
    }
}
