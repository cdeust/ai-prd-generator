import Foundation

/// Captures every LLM interaction for audit and learning
/// Foundation for intelligence layer - tracks all AI calls
public struct LLMInteractionTrace: Identifiable, Sendable, Codable {
    public let id: UUID
    public let prdId: UUID?  // Nullable: LLM calls happen before PRD exists, updated via upsert
    public let sectionId: UUID?
    public let timestamp: Date
    public let purpose: InteractionPurpose
    public let contextType: ContextType?
    public let promptTemplate: String
    public let actualPrompt: String
    public let systemInstructions: String?
    public let llmModel: String
    public let provider: String
    public let parameters: LLMParameters
    public let response: String
    public let responseMetadata: [String: String]?
    public let tokensPrompt: Int?
    public let tokensResponse: Int?
    public let tokensTotal: Int?
    public let latencyMs: Int?
    public let costUsd: Double?
    public let thinkingStrategy: String?
    public let thinkingDepth: Int?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        prdId: UUID? = nil,
        sectionId: UUID? = nil,
        timestamp: Date = Date(),
        purpose: InteractionPurpose,
        contextType: ContextType? = nil,
        promptTemplate: String,
        actualPrompt: String,
        systemInstructions: String? = nil,
        llmModel: String,
        provider: String,
        parameters: LLMParameters = LLMParameters(),
        response: String,
        responseMetadata: [String: String]? = nil,
        tokensPrompt: Int? = nil,
        tokensResponse: Int? = nil,
        tokensTotal: Int? = nil,
        latencyMs: Int? = nil,
        costUsd: Double? = nil,
        thinkingStrategy: String? = nil,
        thinkingDepth: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.prdId = prdId
        self.sectionId = sectionId
        self.timestamp = timestamp
        self.purpose = purpose
        self.contextType = contextType
        self.promptTemplate = promptTemplate
        self.actualPrompt = actualPrompt
        self.systemInstructions = systemInstructions
        self.llmModel = llmModel
        self.provider = provider
        self.parameters = parameters
        self.response = response
        self.responseMetadata = responseMetadata
        self.tokensPrompt = tokensPrompt
        self.tokensResponse = tokensResponse
        self.tokensTotal = tokensTotal
        self.latencyMs = latencyMs
        self.costUsd = costUsd
        self.thinkingStrategy = thinkingStrategy
        self.thinkingDepth = thinkingDepth
        self.createdAt = createdAt
    }
}
