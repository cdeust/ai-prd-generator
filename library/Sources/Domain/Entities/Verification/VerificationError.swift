import Foundation

/// Verification errors for clarification flow
/// Following Single Responsibility: Represents verification failures
public enum VerificationError: Error, LocalizedError {
    case verificationFailed(score: Double, reason: String)
    case maxRefinementAttemptsExceeded(attempts: Int, finalScore: Double, recommendations: [String])

    public var errorDescription: String? {
        switch self {
        case .verificationFailed(let score, let reason):
            return "Verification failed with score \(score): \(reason)"
        case .maxRefinementAttemptsExceeded(let attempts, let score, let recommendations):
            return """
            Maximum refinement attempts (\(attempts)) exceeded. \
            Final score: \(score). \
            Recommendations: \(recommendations.joined(separator: ", "))
            """
        }
    }
}
