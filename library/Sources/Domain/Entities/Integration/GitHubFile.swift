import Foundation

/// GitHub file information
public struct GitHubFile: Sendable {
    public let path: String
    public let name: String
    public let content: String?
    public let size: Int
    public let downloadUrl: String?

    public init(
        path: String,
        name: String,
        content: String? = nil,
        size: Int,
        downloadUrl: String?
    ) {
        self.path = path
        self.name = name
        self.content = content
        self.size = size
        self.downloadUrl = downloadUrl
    }
}
