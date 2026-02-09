import AIPRDSharedUtilities
import Foundation

/// Merkle node database record
internal struct PGMerkleNodeRecord: Encodable {
    let id: String
    let projectId: String
    let chunkId: String?
    let hash: String
    let leftChildId: String?
    let rightChildId: String?
    let level: Int
    let position: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case chunkId = "chunk_id"
        case hash
        case leftChildId = "left_child_id"
        case rightChildId = "right_child_id"
        case level
        case position
        case createdAt = "created_at"
    }
}
