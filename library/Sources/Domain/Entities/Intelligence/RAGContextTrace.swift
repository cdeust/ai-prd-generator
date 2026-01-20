import Foundation

/// Tracks RAG retrieval decisions and their impact
/// Enables learning from which code context helps PRD quality
public struct RAGContextTrace: Identifiable, Sendable, Codable {
    public let id: UUID
    public let prdId: UUID?  // Nullable: set via upsert when PRD is created
    public let sectionId: UUID?
    public let codebaseId: UUID
    public let llmInteractionId: UUID?
    public let query: String
    public let queryType: RAGQueryType
    public let retrievedChunks: [RetrievedChunk]
    public let chunkIds: [UUID]
    public let relevanceScores: [Double]
    public let retrievalMethod: RetrievalMethod
    public let reasoningForSelection: String
    public let impactOnOutput: String?
    public let userFeedback: Bool?
    public let actualUsefulness: RAGUsefulness?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        prdId: UUID? = nil,
        sectionId: UUID? = nil,
        codebaseId: UUID,
        llmInteractionId: UUID? = nil,
        query: String,
        queryType: RAGQueryType,
        retrievedChunks: [RetrievedChunk] = [],
        chunkIds: [UUID] = [],
        relevanceScores: [Double] = [],
        retrievalMethod: RetrievalMethod,
        reasoningForSelection: String,
        impactOnOutput: String? = nil,
        userFeedback: Bool? = nil,
        actualUsefulness: RAGUsefulness? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.prdId = prdId
        self.sectionId = sectionId
        self.codebaseId = codebaseId
        self.llmInteractionId = llmInteractionId
        self.query = query
        self.queryType = queryType
        self.retrievedChunks = retrievedChunks
        self.chunkIds = chunkIds
        self.relevanceScores = relevanceScores
        self.retrievalMethod = retrievalMethod
        self.reasoningForSelection = reasoningForSelection
        self.impactOnOutput = impactOnOutput
        self.userFeedback = userFeedback
        self.actualUsefulness = actualUsefulness
        self.createdAt = createdAt
    }
}
