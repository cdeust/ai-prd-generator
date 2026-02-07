import AIPRDSharedUtilities
import Foundation

/// Errors that can occur during file DTO to domain mapping
enum FileMappingError: Error {
    case invalidUUID
    case invalidLanguage(String)
}
