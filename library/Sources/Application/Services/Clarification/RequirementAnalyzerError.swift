import Foundation

public enum RequirementAnalyzerError: Error {
    case serviceReleased
    case parsingFailed(String)
    case invalidResponse(String)
}

extension RequirementAnalyzerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .serviceReleased:
            return "Requirement analyzer service was released during operation"
        case .parsingFailed(let details):
            return "Failed to parse AI response: \(details)"
        case .invalidResponse(let details):
            return "Invalid AI response format: \(details)"
        }
    }
}
