import Foundation

/// Recommendation on whether to attempt refinement
public struct RefinementRecommendation: Sendable {
    public let shouldRefine: Bool
    public let reason: String
    public let maxAttempts: Int
}
