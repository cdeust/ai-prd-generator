import Foundation

/// Supabase count query result DTO
/// Maps to Supabase count response format
public struct SupabaseCountResult: Decodable {
    let count: Int
}
