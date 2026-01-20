import Foundation

/// Errors specific to codebase operations
/// Single Responsibility: Domain errors for codebase use cases
public enum CodebaseError: Error {
    case invalidName
    case alreadyExists
}
