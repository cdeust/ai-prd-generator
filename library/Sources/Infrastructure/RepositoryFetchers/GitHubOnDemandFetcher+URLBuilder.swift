import Foundation

/// URL building helpers for GitHub API requests
extension GitHubOnDemandFetcher {
    func buildTreeURL(owner: String, repo: String, branch: String) -> URL {
        URL(string: "https://api.github.com/repos/\(owner)/\(repo)/git/trees/\(branch)?recursive=1")!
    }

    func buildContentURL(owner: String, repo: String, path: String, branch: String) -> URL {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(encodedPath)?ref=\(branch)"
        return URL(string: urlString)!
    }

    func buildRequest(url: URL, accessToken: String?) -> HTTPRequest {
        var headers = ["Accept": "application/vnd.github.v3+json"]
        if let token = accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        return HTTPRequest(url: url, method: .get, headers: headers)
    }
}
