import Foundation

/// Detailed step in the thinking process
/// Captures reasoning for transparency and debugging
public struct ThinkingChainStep: Identifiable, Sendable, Codable {
    public let id: UUID
    public let prdId: UUID?  // Nullable: set via upsert when PRD is created
    public let sectionId: UUID?
    public let llmInteractionId: UUID?
    public let stepNumber: Int
    public let thoughtType: ThoughtStepType
    public let content: String
    public let evidenceUsed: [EvidenceReference]
    public let confidence: Double?
    public let tokensUsed: Int?
    public let executionTimeMs: Int?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        prdId: UUID? = nil,
        sectionId: UUID? = nil,
        llmInteractionId: UUID? = nil,
        stepNumber: Int,
        thoughtType: ThoughtStepType,
        content: String,
        evidenceUsed: [EvidenceReference] = [],
        confidence: Double? = nil,
        tokensUsed: Int? = nil,
        executionTimeMs: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.prdId = prdId
        self.sectionId = sectionId
        self.llmInteractionId = llmInteractionId
        self.stepNumber = stepNumber
        self.thoughtType = thoughtType
        self.content = content
        self.evidenceUsed = evidenceUsed
        self.confidence = confidence
        self.tokensUsed = tokensUsed
        self.executionTimeMs = executionTimeMs
        self.createdAt = createdAt
    }
}
