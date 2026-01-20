import Foundation

/// Merkle tree for codebase integrity
/// Following Single Responsibility Principle - represents merkle tree
public struct MerkleTree: Sendable {
    public let rootHash: String
    public let rootNode: MerkleNode?
    public let totalFiles: Int
    public let createdAt: Date

    public init(
        rootHash: String,
        rootNode: MerkleNode? = nil,
        totalFiles: Int,
        createdAt: Date = Date()
    ) {
        self.rootHash = rootHash
        self.rootNode = rootNode
        self.totalFiles = totalFiles
        self.createdAt = createdAt
    }
}
