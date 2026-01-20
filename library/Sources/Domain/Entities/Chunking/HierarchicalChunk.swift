import Foundation

/// Hierarchical chunk structure
public struct HierarchicalChunk: Sendable, Codable {
    public let id: UUID
    public let content: String
    public let level: Int
    public let tokenCount: Int
    public let children: [HierarchicalChunk]

    public init(
        id: UUID = UUID(),
        content: String,
        level: Int,
        tokenCount: Int,
        children: [HierarchicalChunk] = []
    ) {
        self.id = id
        self.content = content
        self.level = level
        self.tokenCount = tokenCount
        self.children = children
    }
}
