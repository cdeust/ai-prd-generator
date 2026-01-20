import Foundation

/// Merkle root hash update DTO
/// Backend compatibility layer (ONLY exception per Rule 8)
/// Single Responsibility: Update Merkle root hash in database
struct MerkleRootUpdate: Encodable {
    let merkleRootHash: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case merkleRootHash = "merkle_root_hash"
        case updatedAt = "updated_at"
    }
}
