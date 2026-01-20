import Foundation
import Domain

/// Enriched context for PRD generation
///
/// Combines base request with intelligence from RAG, reasoning, and vision
/// to create comprehensive context for AI generation.
public struct EnrichedPRDContext: Sendable {
    public let baseRequest: PRDRequest
    public let ragResults: RAGSearchResults?
    public let reasoningPlan: ReasoningPlan?
    public let visionResults: [MockupAnalysisResult]?
    public let aggregatedContext: String

    public init(
        baseRequest: PRDRequest,
        ragResults: RAGSearchResults?,
        reasoningPlan: ReasoningPlan?,
        visionResults: [MockupAnalysisResult]? = nil,
        aggregatedContext: String
    ) {
        self.baseRequest = baseRequest
        self.ragResults = ragResults
        self.reasoningPlan = reasoningPlan
        self.visionResults = visionResults
        self.aggregatedContext = aggregatedContext
    }
}

