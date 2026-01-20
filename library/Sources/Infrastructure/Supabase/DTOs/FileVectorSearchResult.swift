import Foundation

/// File vector search result DTO
/// Backend compatibility layer (ONLY exception per Rule 8)
/// Single Responsibility: Represents file similarity search result from RPC
struct FileVectorSearchResult: Decodable {
    let file: SupabaseCodeFileRecord
    let similarity: Float
}
