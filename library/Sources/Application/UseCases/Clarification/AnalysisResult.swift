import Foundation
import Domain

/// Result of Phase 1 analysis containing session and context
public struct AnalysisResult: Sendable {
    /// Clarification session with questions for the user
    public let session: ClarificationSession<String, Int, String>

    /// Enriched context built from RAG, vision, and reasoning
    public let enrichedContext: EnrichedPRDContext?

    /// Whether there are questions that need user answers
    public let hasQuestions: Bool

    public init(
        session: ClarificationSession<String, Int, String>,
        enrichedContext: EnrichedPRDContext?,
        hasQuestions: Bool
    ) {
        self.session = session
        self.enrichedContext = enrichedContext
        self.hasQuestions = hasQuestions
    }
}
