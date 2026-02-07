import AIPRDSharedUtilities
import Foundation

/// Update struct for Merkle root
internal struct PGMerkleRootUpdate: Encodable {
    let merkleRootHash: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case merkleRootHash = "merkle_root_hash"
        case updatedAt = "updated_at"
    }
}
