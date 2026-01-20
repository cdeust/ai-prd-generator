import Foundation

/// Tracks clarification questions and their impact on PRD quality
/// Enables learning from question effectiveness
public struct ClarificationTrace: Identifiable, Sendable, Codable {
    public let id: UUID
    public let prdId: UUID?  // Nullable: clarifications happen before PRD exists, updated via upsert
    public let questionId: UUID
    public let questionText: String
    public let questionCategory: ClarificationCategory?
    public let reasoningForAsking: String
    public let gapAddressed: String
    public let userAnswer: String?
    public let answerTimestamp: Date?
    public let impactOnPrd: String?
    public let influencedSections: [UUID]
    public let wasHelpful: Bool?
    public let improvedQuality: Bool?
    public let shouldAskAgainForSimilar: Bool?
    public let coherenceScore: Double?  // Pre-ask coherence score (0.0-1.0)
    public let valueAddScore: Double?   // Pre-ask value-add score (0.0-1.0)
    public let wasAskedToUser: Bool     // Whether question passed threshold and was asked
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        prdId: UUID? = nil,
        questionId: UUID,
        questionText: String,
        questionCategory: ClarificationCategory? = nil,
        reasoningForAsking: String,
        gapAddressed: String,
        userAnswer: String? = nil,
        answerTimestamp: Date? = nil,
        impactOnPrd: String? = nil,
        influencedSections: [UUID] = [],
        wasHelpful: Bool? = nil,
        improvedQuality: Bool? = nil,
        shouldAskAgainForSimilar: Bool? = nil,
        coherenceScore: Double? = nil,
        valueAddScore: Double? = nil,
        wasAskedToUser: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.prdId = prdId
        self.questionId = questionId
        self.questionText = questionText
        self.questionCategory = questionCategory
        self.reasoningForAsking = reasoningForAsking
        self.gapAddressed = gapAddressed
        self.userAnswer = userAnswer
        self.answerTimestamp = answerTimestamp
        self.impactOnPrd = impactOnPrd
        self.influencedSections = influencedSections
        self.wasHelpful = wasHelpful
        self.improvedQuality = improvedQuality
        self.shouldAskAgainForSimilar = shouldAskAgainForSimilar
        self.coherenceScore = coherenceScore
        self.valueAddScore = valueAddScore
        self.wasAskedToUser = wasAskedToUser
        self.createdAt = createdAt
    }
}
