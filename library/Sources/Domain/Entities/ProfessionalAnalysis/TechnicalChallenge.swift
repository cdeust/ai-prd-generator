import Foundation

/// Technical challenge identified in requirements
/// Following Single Responsibility Principle - represents single challenge
public struct TechnicalChallenge: Identifiable, Sendable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let severity: ChallengeSeverity
    public let category: ChallengeCategory
    public let suggestedApproach: String?
    public let estimatedComplexity: Int // 1-10

    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        severity: ChallengeSeverity,
        category: ChallengeCategory,
        suggestedApproach: String? = nil,
        estimatedComplexity: Int
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.severity = severity
        self.category = category
        self.suggestedApproach = suggestedApproach
        self.estimatedComplexity = estimatedComplexity
    }
}
