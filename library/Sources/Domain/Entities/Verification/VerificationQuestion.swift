import Foundation

/// Question used to verify the accuracy or adequacy of a response
/// Part of Chain of Verification (CoV) pattern - Step 2
/// Following Single Responsibility: Represents a single verification question
public struct VerificationQuestion: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let question: String
    public let category: VerificationCategory
    public let priority: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        question: String,
        category: VerificationCategory,
        priority: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.question = question
        self.category = category
        self.priority = priority
        self.createdAt = createdAt
    }
}
