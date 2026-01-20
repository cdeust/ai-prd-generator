import Foundation

/// Merkle tree node for code integrity verification
/// Following Single Responsibility Principle - represents merkle tree node
public indirect enum MerkleNode: Sendable {
    case leaf(id: UUID, hash: String, filePath: String)
    case branch(id: UUID, hash: String, left: MerkleNode, right: MerkleNode)

    public var id: UUID {
        switch self {
        case .leaf(let id, _, _): return id
        case .branch(let id, _, _, _): return id
        }
    }

    public var hash: String {
        switch self {
        case .leaf(_, let hash, _): return hash
        case .branch(_, let hash, _, _): return hash
        }
    }

    public var isLeaf: Bool {
        if case .leaf = self { return true }
        return false
    }
}
