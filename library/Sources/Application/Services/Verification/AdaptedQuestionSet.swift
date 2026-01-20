import Foundation
import Domain

/// Result of adaptive question selection
/// Single Responsibility: Represents selected questions with metadata
public struct AdaptedQuestionSet: Sendable {
    public let original: [VerificationQuestion]
    public let adapted: [VerificationQuestion]
    public let addedCount: Int
    public let reason: String

    public init(
        original: [VerificationQuestion],
        adapted: [VerificationQuestion],
        addedCount: Int,
        reason: String
    ) {
        self.original = original
        self.adapted = adapted
        self.addedCount = addedCount
        self.reason = reason
    }
}
