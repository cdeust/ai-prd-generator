import AIPRDSharedUtilities
import Foundation

/// Encodable struct for user ID update operations
/// Used for repository connection user ID updates
struct RepositoryConnectionUserIdUpdate: Encodable {
    let userId: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}
