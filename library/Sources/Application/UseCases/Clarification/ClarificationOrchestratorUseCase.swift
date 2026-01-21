import Foundation
import Domain

/// Orchestrates multi-turn clarification dialogue to enrich PRD requests
///
/// Professional implementation:
/// - Infinite rounds - purely user-driven stopping
/// - Completeness threshold configurable (default: 0.9)
/// - Temperature configurable for analysis
/// - Returns .readyToComplete when threshold reached, user decides to proceed or continue
/// - Generates PRD internally when clarification complete (library owns full flow)
public actor ClarificationOrchestratorUseCase {
    private let analyzer: RequirementAnalyzerService
    private let prdGenerator: GeneratePRDUseCase
    private let completenessThreshold: Double

    public init(
        analyzer: RequirementAnalyzerService,
        prdGenerator: GeneratePRDUseCase,
        completenessThreshold: Double = 0.9
    ) {
        self.analyzer = analyzer
        self.prdGenerator = prdGenerator
        self.completenessThreshold = completenessThreshold
    }

    /// Start clarification session with initial PRD request
    ///
    /// Uses adaptive temperature strategy for optimal confidence.
    /// If completeness threshold already met, returns empty session (no questions needed).
    ///
    /// - Parameter initialRequest: Initial PRD request from user
    /// - Returns: New clarification session with initial gap analysis (or empty if complete)
    /// - Throws: AIProviderError if analysis fails
    public func startClarification(
        initialRequest: PRDRequest
    ) async throws -> ClarificationSession<String, Int, String> {
        let analysis = try await analyzer.analyzeRequirements(initialRequest)

        // If already complete, return session with no questions
        let session = ClarificationSession(
            userId: initialRequest.userId,
            title: initialRequest.title,
            description: initialRequest.description,
            currentAnalysis: analysis,
            answers: [:],
            round: 1
        )

        return session
    }

    /// Submit answer to a clarification question
    ///
    /// Uses adaptive temperature strategy for re-analysis.
    /// Generates PRD internally when clarification is complete.
    ///
    /// - Parameters:
    ///   - session: Current clarification session
    ///   - questionId: ID of question being answered
    ///   - answer: User's answer
    ///   - userWantsToProceed: If true, force completion regardless of threshold (user decision)
    /// - Returns: Result indicating completion with PRD, ready to complete, or continuation with new questions
    /// - Throws: AIProviderError if re-analysis or PRD generation fails
    public func submitAnswer(
        session: ClarificationSession<String, Int, String>,
        questionId: UUID,
        answer: String,
        userWantsToProceed: Bool = false
    ) async throws -> ClarificationResult {
        let updatedSession = session.withAnswer(questionId: questionId, answer: answer)

        // Check if ALL questions from current round are answered
        let allQuestionsAnswered = updatedSession.currentAnalysis.questions.allSatisfy { question in
            updatedSession.answers[question.id] != nil
        }

        // If not all questions answered, return updated session (don't re-analyze yet)
        if !allQuestionsAnswered {
            return .continueWithQuestions(updatedSession)
        }

        // All questions answered - check if user wants to proceed or we should continue
        let updatedRequest = buildEnrichedRequest(from: updatedSession)

        // If user explicitly wants to proceed, generate PRD immediately
        if userWantsToProceed {
            let document = try await prdGenerator.execute(updatedRequest)
            return .complete(document)
        }

        // Re-analyze with enriched context to check completeness
        let analysis = try await analyzer.analyzeRequirements(updatedRequest)

        // If completeness threshold reached, offer user choice to proceed or continue
        if analysis.completenessScore >= completenessThreshold {
            return .readyToComplete(updatedSession, currentCompleteness: analysis.completenessScore)
        }

        // Filter out already asked questions to avoid duplicates
        let alreadyAskedIds = Set(updatedSession.currentAnalysis.questions.map { $0.id })
        let newQuestions = analysis.questions.filter { !alreadyAskedIds.contains($0.id) }

        // If no new questions but still not complete, just generate with what we have
        guard !newQuestions.isEmpty else {
            let document = try await prdGenerator.execute(updatedRequest)
            return .complete(document)
        }

        // Create new analysis with only new questions
        let filteredAnalysis = GapAnalysisResult(
            completenessScore: analysis.completenessScore,
            detectedGaps: analysis.detectedGaps,
            questions: newQuestions,
            confidence: analysis.confidence
        )

        let nextSession = updatedSession.withNewAnalysis(filteredAnalysis)
        return .continueWithQuestions(nextSession)
    }

    private func shouldComplete(_ session: ClarificationSession<String, Int, String>) -> Bool {
        let completenessReached = session.currentAnalysis.completenessScore >= completenessThreshold
        let allCriticalAnswered = areAllCriticalQuestionsAnswered(session)

        return completenessReached && allCriticalAnswered
    }

    private func areAllCriticalQuestionsAnswered(
        _ session: ClarificationSession<String, Int, String>
    ) -> Bool {
        let criticalQuestions = session.currentAnalysis.questions
            .filter { $0.priority.value >= 90 }

        return criticalQuestions.allSatisfy { question in
            session.answers[question.id] != nil
        }
    }

    private func buildEnrichedRequest(
        from session: ClarificationSession<String, Int, String>
    ) -> PRDRequest {
        var enrichedDescription = session.description

        let answeredQuestions = session.currentAnalysis.questions
            .filter { session.answers[$0.id] != nil }
            .sorted { $0.priority > $1.priority }

        for question in answeredQuestions {
            if let answer = session.answers[question.id] {
                let categoryLabel = question.category.value.capitalized
                enrichedDescription += "\n\n**\(categoryLabel):** \(answer)"
            }
        }

        return PRDRequest(
            userId: session.userId,
            title: session.title,
            description: enrichedDescription,
            requirements: [],
            constraints: [],
            platform: nil,
            metadata: [
                "clarification_rounds": String(session.round),
                "completeness_score": String(format: "%.2f", session.currentAnalysis.completenessScore),
                "questions_answered": String(session.answers.count)
            ]
        )
    }
}
