import Foundation

/// Errors that can occur during gap detection and resolution.
public enum GapResolutionError: Error, Sendable, Equatable {
    /// Failed to detect gaps from the provided context
    case detectionFailed(reason: String)

    /// Failed to categorize a gap
    case categorizationFailed(gapId: UUID, reason: String)

    /// Failed to prioritize a gap
    case prioritizationFailed(gapId: UUID, reason: String)

    /// Failed to resolve a gap using the specified strategy
    case resolutionFailed(gapId: UUID, strategy: ResolutionStrategy, reason: String)

    /// Resolution attempt returned low confidence result
    case lowConfidence(gapId: UUID, confidence: Double)

    /// Required context (mockup, codebase, etc.) is missing
    case missingContext(contextType: String, gapId: UUID)

    /// Invalid gap or resolution data
    case invalidData(reason: String)

    /// Timeout during resolution attempt
    case timeout(strategy: ResolutionStrategy, duration: TimeInterval)

    /// Maximum resolution attempts exceeded
    case maxAttemptsExceeded(gapId: UUID, attempts: Int)

    /// User escalation required but no user interaction port available
    case userInteractionUnavailable(gapId: UUID)
}

extension GapResolutionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .detectionFailed(let reason):
            return "Failed to detect information gaps: \(reason)"

        case .categorizationFailed(let gapId, let reason):
            return "Failed to categorize gap \(gapId): \(reason)"

        case .prioritizationFailed(let gapId, let reason):
            return "Failed to prioritize gap \(gapId): \(reason)"

        case .resolutionFailed(let gapId, let strategy, let reason):
            return "Failed to resolve gap \(gapId) using \(strategy): \(reason)"

        case .lowConfidence(let gapId, let confidence):
            return "Gap \(gapId) resolution has low confidence (\(Int(confidence * 100))%)"

        case .missingContext(let contextType, let gapId):
            return "Missing required context (\(contextType)) for gap \(gapId)"

        case .invalidData(let reason):
            return "Invalid gap or resolution data: \(reason)"

        case .timeout(let strategy, let duration):
            return "Resolution using \(strategy) timed out after \(duration)s"

        case .maxAttemptsExceeded(let gapId, let attempts):
            return "Maximum resolution attempts (\(attempts)) exceeded for gap \(gapId)"

        case .userInteractionUnavailable(let gapId):
            return "Gap \(gapId) requires user input but user interaction is unavailable"
        }
    }
}
