import Foundation
import Domain

/// Filters clarification questions by coherence and effectiveness
/// Single Responsibility: Question quality filtering using coherence scoring
struct QuestionFilterCoordinator: Sendable {
    private let coherenceScorer: QuestionCoherenceScorer
    private let trackingService: ClarificationTrackingService?

    init(coherenceScorer: QuestionCoherenceScorer, trackingService: ClarificationTrackingService?) {
        self.coherenceScorer = coherenceScorer
        self.trackingService = trackingService
    }

    /// Filter questions by coherence and effectiveness scores
    func filterQuestions(
        _ questions: [ClarificationQuestion<String, Int, String>],
        request: PRDRequest,
        codebaseContext: RAGSearchResults?,
        mockupSummaries: [String]
    ) async throws -> [ClarificationQuestion<String, Int, String>] {
        let allScored = try await coherenceScorer.scoreAllQuestions(
            questions: questions, request: request,
            codebaseContext: codebaseContext, mockupSummaries: mockupSummaries
        )

        await trackingService?.trackQuestionsWithCoherence(allScored)

        let passed = allScored.filter { $0.coherenceScore >= 0.9 && $0.effectivenessScore >= 0.8 }
        print("🎯 [Coherence] Kept \(passed.count)/\(allScored.count)")
        return passed.map { $0.question }
    }
}
