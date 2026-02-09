import AIPRDSharedUtilities
import Foundation

/// GitHub API response for directory contents (internal implementation detail)
/// Used to traverse directory structure when fetching repository files
public struct GitHubContent: Codable, Sendable {
    let name: String
    let path: String
    let type: String  // "file" or "dir"
    let size: Int
    let download_url: String?
}
