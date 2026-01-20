import Foundation

/// Result of threshold adaptation with reasoning
/// Single Responsibility: Represents adapted threshold value with metadata
public struct AdaptedThreshold: Sendable {
    public let original: Double
    public let adapted: Double
    public let adjustment: Double
    public let reason: String
    public let confidence: Double

    public init(
        original: Double,
        adapted: Double,
        adjustment: Double,
        reason: String,
        confidence: Double
    ) {
        self.original = original
        self.adapted = adapted
        self.adjustment = adjustment
        self.reason = reason
        self.confidence = confidence
    }
}
