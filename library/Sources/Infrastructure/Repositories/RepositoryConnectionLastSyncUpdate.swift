import AIPRDSharedUtilities
import Foundation

/// Encodable struct for last sync update operations
/// Used for repository connection sync timestamp updates
struct RepositoryConnectionLastSyncUpdate: Encodable {
    let lastSyncedAt: Date

    enum CodingKeys: String, CodingKey {
        case lastSyncedAt = "last_synced_at"
    }
}
