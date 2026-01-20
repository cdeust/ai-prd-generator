import Foundation

/// Supabase vector search result DTO
/// Backend compatibility layer (ONLY exception per Rule 8)
/// Single Responsibility: Represents chunk similarity search result from RPC
public struct SupabaseVectorSearchResult: Decodable {
    let chunk: SupabaseCodeChunkRecord
    let similarity: Double
}
