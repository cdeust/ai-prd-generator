import Foundation
import Domain

/// Merkle tree node record DTO
/// Backend compatibility layer (ONLY exception per Rule 8)
/// Single Responsibility: Represents Merkle tree node in database
struct MerkleNodeRecord: Codable {
    let id: String
    let projectId: String
    let nodeHash: String
    let leftHash: String?
    let rightHash: String?
    let chunkId: String?
    let level: Int
    let position: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case nodeHash = "node_hash"
        case leftHash = "left_hash"
        case rightHash = "right_hash"
        case chunkId = "chunk_id"
        case level
        case position
        case createdAt = "created_at"
    }

    init(from node: MerkleNode, projectId: UUID, level: Int, position: Int) {
        self.id = node.id.uuidString
        self.projectId = projectId.uuidString
        self.nodeHash = node.hash
        self.level = level
        self.position = position
        self.createdAt = Date()

        switch node {
        case .leaf:
            self.leftHash = nil
            self.rightHash = nil
            self.chunkId = nil
        case .branch(_, _, let left, let right):
            self.leftHash = left.hash
            self.rightHash = right.hash
            self.chunkId = nil
        }
    }

    /// Custom encode to ensure all keys are present (PostgREST requires consistent keys in batch inserts)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(nodeHash, forKey: .nodeHash)
        try container.encode(leftHash, forKey: .leftHash)  // Encodes null if nil
        try container.encode(rightHash, forKey: .rightHash)  // Encodes null if nil
        try container.encode(chunkId, forKey: .chunkId)  // Encodes null if nil
        try container.encode(level, forKey: .level)
        try container.encode(position, forKey: .position)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
