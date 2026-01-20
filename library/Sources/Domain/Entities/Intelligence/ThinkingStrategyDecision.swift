import Foundation

/// Records why a particular thinking strategy was chosen
/// Enables learning from strategy selection decisions
public struct ThinkingStrategyDecision: Identifiable, Sendable, Codable {
    public let id: UUID
    public let prdId: UUID?  // Nullable: set via upsert when PRD is created
    public let sectionId: UUID?
    public let strategyChosen: String
    public let reasoning: String
    public let confidenceScore: Double?
    public let inputCharacteristics: InputCharacteristics
    public let alternativesConsidered: [String]
    public let actualPerformance: StrategyPerformance?
    public let wasEffective: Bool?
    public let lessonsLearned: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        prdId: UUID? = nil,
        sectionId: UUID? = nil,
        strategyChosen: String,
        reasoning: String,
        confidenceScore: Double? = nil,
        inputCharacteristics: InputCharacteristics = InputCharacteristics(),
        alternativesConsidered: [String] = [],
        actualPerformance: StrategyPerformance? = nil,
        wasEffective: Bool? = nil,
        lessonsLearned: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.prdId = prdId
        self.sectionId = sectionId
        self.strategyChosen = strategyChosen
        self.reasoning = reasoning
        self.confidenceScore = confidenceScore
        self.inputCharacteristics = inputCharacteristics
        self.alternativesConsidered = alternativesConsidered
        self.actualPerformance = actualPerformance
        self.wasEffective = wasEffective
        self.lessonsLearned = lessonsLearned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
