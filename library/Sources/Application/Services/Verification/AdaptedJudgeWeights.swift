import Foundation

/// Result of judge weight adaptation with change tracking
/// Single Responsibility: Represents adapted judge weights with metadata
public struct AdaptedJudgeWeights: Sendable {
    public let original: [String: Double]
    public let adapted: [String: Double]
    public let changes: [String: Double]
    public let reason: String

    public init(
        original: [String: Double],
        adapted: [String: Double],
        changes: [String: Double],
        reason: String
    ) {
        self.original = original
        self.adapted = adapted
        self.changes = changes
        self.reason = reason
    }
}
