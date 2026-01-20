import Foundation

/// Supabase API error response DTO
/// Maps to Supabase REST API error format
public struct SupabaseErrorResponse: Decodable {
    let code: String?
    let message: String
    let hint: String?
}
