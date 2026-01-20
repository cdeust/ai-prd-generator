import Foundation
import Domain

/// Internal container for storing session metadata and messages in JSONB
/// Used by SupabaseSessionMapper for JSON serialization
struct SessionMetadataContainer: Codable {
    let metadata: SessionMetadata
    let messages: [ChatMessage]
}
