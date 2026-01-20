import Foundation

/// Encodable struct for user ID update operations
/// Used by SupabaseRepositoryConnectionRepository for updating user ID
struct RepositoryConnectionUserIdUpdate: Encodable {
    let userId: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}
