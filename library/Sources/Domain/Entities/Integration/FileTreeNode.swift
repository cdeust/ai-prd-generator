import Foundation

/// File tree node entity
/// Represents a file or directory in repository tree
public struct FileTreeNode: Sendable {
    public let path: String
    public let type: NodeType
    public let size: Int?
    public let sha: String?

    public init(
        path: String,
        type: NodeType,
        size: Int? = nil,
        sha: String? = nil
    ) {
        self.path = path
        self.type = type
        self.size = size
        self.sha = sha
    }

    /// Node type enumeration
    public enum NodeType: String, Sendable {
        case file
        case directory
    }

    /// Check if file is supported for indexing
    public var isSupported: Bool {
        guard type == .file else { return false }
        let supportedExtensions = [
            ".swift", ".kt", ".ts", ".js", ".py", ".java",
            ".go", ".rs", ".cs", ".cpp", ".h", ".m", ".mm"
        ]
        return supportedExtensions.contains { path.hasSuffix($0) }
    }
}
