import AIPRDSharedUtilities
import Foundation

/// Errors that can occur during DTO to domain mapping
enum MappingError: Error {
    case invalidUUID
    case invalidLanguage(String)
    case invalidChunkType(String)
}
