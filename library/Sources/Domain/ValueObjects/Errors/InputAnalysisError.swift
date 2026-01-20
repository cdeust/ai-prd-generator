import Foundation

/// Errors that occur during input analysis
public enum InputAnalysisError: Error, Sendable, Equatable {
    /// Empty text description provided
    case emptyTextDescription

    /// Empty mockup images array provided
    case emptyMockupImages

    /// Invalid codebase identifier
    case invalidCodebaseId

    /// Analysis failed
    case analysisFailed(reason: String)

    /// Aggregation failed
    case aggregationFailed(reason: String)
}

extension InputAnalysisError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyTextDescription:
            return "Text description cannot be empty"
        case .emptyMockupImages:
            return "Mockup images array cannot be empty"
        case .invalidCodebaseId:
            return "Invalid codebase identifier"
        case .analysisFailed(let reason):
            return "Input analysis failed: \(reason)"
        case .aggregationFailed(let reason):
            return "Context aggregation failed: \(reason)"
        }
    }
}
