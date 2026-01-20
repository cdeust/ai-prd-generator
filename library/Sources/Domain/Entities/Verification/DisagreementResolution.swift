import Foundation

/// Resolution strategy for judge disagreement
/// Following Professional Implementation Standards: Data-driven decisions
public enum DisagreementResolution: Sendable, Codable, Equatable {
    /// Agreement acceptable - use consensus score
    case accept(score: Double, confidence: Double)

    /// Try again with refined prompts
    case reEvaluate(reason: String)

    /// Manual review needed - judges fundamentally disagree
    case flagForReview(concerns: [String])

    /// Too much disagreement - discard and regenerate
    case reject(reason: String)

    /// Whether this resolution requires action
    public var requiresAction: Bool {
        switch self {
        case .accept:
            return false
        case .reEvaluate, .flagForReview, .reject:
            return true
        }
    }

    /// Severity level for monitoring and alerting
    public var severityLevel: SeverityLevel {
        switch self {
        case .accept:
            return .normal
        case .reEvaluate:
            return .warning
        case .flagForReview:
            return .high
        case .reject:
            return .critical
        }
    }
}
