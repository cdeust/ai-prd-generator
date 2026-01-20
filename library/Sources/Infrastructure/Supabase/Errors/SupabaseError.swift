import Foundation

/// Supabase-specific errors
/// Domain value object for Supabase error handling
public enum SupabaseError: Error {
    case invalidURL(String)
    case apiError(code: String, message: String)
    case httpError(statusCode: Int, data: Data)
    case decodingFailed(Error)
}
