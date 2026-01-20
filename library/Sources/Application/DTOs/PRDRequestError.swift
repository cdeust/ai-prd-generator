import Foundation

/// Errors related to PRD request validation
/// Following Single Responsibility Principle - encapsulates PRD request errors
public enum PRDRequestError: Error {
    case emptyTitle
    case emptyDescription
    case missingCodebase
    case missingMockups

    public var localizedDescription: String {
        switch self {
        case .emptyTitle:
            return "PRD title cannot be empty"
        case .emptyDescription:
            return "PRD description cannot be empty"
        case .missingCodebase:
            return "Codebase selection is required for PRD generation"
        case .missingMockups:
            return "Mockups are required for PRD generation"
        }
    }
}
