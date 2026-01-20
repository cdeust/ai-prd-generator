import Foundation
import Domain

/// Coordinates refinement of clarification questions based on verification feedback
/// Single Responsibility: Question refinement loop with meta-learning
public actor ClarificationRefinementCoordinator {
    private let analyzer: RequirementAnalyzerService
    private let verificationService: ChainOfVerificationService
    private let historicalAnalyzer: HistoricalVerificationAnalyzer?
    private let evidenceRepository: VerificationEvidenceRepositoryPort?

    public init(
        analyzer: RequirementAnalyzerService,
        verificationService: ChainOfVerificationService,
        historicalAnalyzer: HistoricalVerificationAnalyzer? = nil,
        evidenceRepository: VerificationEvidenceRepositoryPort? = nil
    ) {
        self.analyzer = analyzer
        self.verificationService = verificationService
        self.historicalAnalyzer = historicalAnalyzer
        self.evidenceRepository = evidenceRepository
    }

    /// CoV STEP 4: Refine questions based on verification feedback
    /// META-LEARNING: Uses historical data to determine if refinement is worthwhile
    public func refineQuestions(
        session: ClarificationSession<String, Int, String>,
        verificationResult: CoVVerificationResult,
        originalRequest: PRDRequest,
        verifyQuestionsCallback: (
            [ClarificationQuestion<String, Int, String>],
            String,
            Double?,
            UUID?
        ) async throws -> CoVVerificationResult
    ) async throws -> (
        session: ClarificationSession<String, Int, String>,
        verification: CoVVerificationResult
    ) {
        var currentSession = session
        var currentVerification = verificationResult

        // META-LEARNING: Check if refinement is historically effective
        let recommendation = try await shouldAttemptRefinement(
            entityType: .clarificationSession,
            currentAttempt: currentSession.refinementAttempts
        )

        let maxAttempts = recommendation.shouldRefine
            ? recommendation.maxAttempts
            : 0

        while !currentVerification.verified &&
              currentSession.refinementAttempts < maxAttempts {

            try checkMinimumScore(currentVerification)

            let refinedAnalysis = try await refineAnalysis(
                session: currentSession,
                verificationResult: currentVerification,
                originalRequest: originalRequest
            )

            // META-LEARNING: Use adaptive threshold for refinement verification
            let threshold = try await getAdaptiveThreshold(for: .questionRelevance)

            currentVerification = try await verifyQuestionsCallback(
                refinedAnalysis.questions,
                originalRequest.description,
                threshold,
                currentSession.id
            )

            currentSession = currentSession.withRefinedAnalysis(
                refinedAnalysis,
                verificationResult: currentVerification
            )
        }

        guard currentVerification.verified else {
            throw VerificationError.maxRefinementAttemptsExceeded(
                attempts: maxAttempts,
                finalScore: currentVerification.overallScore,
                recommendations: currentVerification.recommendations
            )
        }

        return (currentSession, currentVerification)
    }

    /// Check if verification score meets minimum threshold for refinement
    private func checkMinimumScore(_ verification: CoVVerificationResult) throws {
        if verification.overallScore < VerificationThresholds.minimumReEvaluationScore {
            throw VerificationError.verificationFailed(
                score: verification.overallScore,
                reason: "Questions scored too low. Cannot refine. " +
                       "Recommendations: \(verification.recommendations.joined(separator: ", "))"
            )
        }
    }

    /// Refine analysis by filtering low-scoring questions or regenerating
    private func refineAnalysis(
        session: ClarificationSession<String, Int, String>,
        verificationResult: CoVVerificationResult,
        originalRequest: PRDRequest
    ) async throws -> GapAnalysisResult<String, Int, String> {
        let lowScoreConsensus = verificationResult.consensusResults
            .filter { $0.consensusScore < 0.6 }

        let filteredQuestions = session.currentAnalysis.questions
            .filter { question in
                !lowScoreConsensus.contains {
                    $0.verificationQuestionId == question.id
                }
            }

        if filteredQuestions.count < 2 {
            return try await regenerateQuestionsFromFeedback(
                originalRequest: originalRequest,
                verificationResult: verificationResult,
                currentQuestions: session.currentAnalysis.questions
            )
        } else {
            return GapAnalysisResult(
                completenessScore: session.currentAnalysis.completenessScore,
                detectedGaps: session.currentAnalysis.detectedGaps,
                questions: filteredQuestions,
                confidence: session.currentAnalysis.confidence
            )
        }
    }

    /// Regenerate questions entirely based on verification feedback
    private func regenerateQuestionsFromFeedback(
        originalRequest: PRDRequest,
        verificationResult: CoVVerificationResult,
        currentQuestions: [ClarificationQuestion<String, Int, String>]
    ) async throws -> GapAnalysisResult<String, Int, String> {
        let feedbackPrompt = buildRegenerationPrompt(
            originalRequest: originalRequest,
            verificationResult: verificationResult,
            failedQuestions: currentQuestions
        )

        let enrichedRequest = PRDRequest(
            userId: originalRequest.userId,
            title: originalRequest.title,
            description: feedbackPrompt,
            requirements: originalRequest.requirements,
            constraints: originalRequest.constraints,
            platform: originalRequest.platform,
            metadata: originalRequest.metadata
        )

        return try await analyzer.analyzeRequirements(enrichedRequest)
    }

    /// Build prompt for regenerating questions with verification feedback
    private func buildRegenerationPrompt(
        originalRequest: PRDRequest,
        verificationResult: CoVVerificationResult,
        failedQuestions: [ClarificationQuestion<String, Int, String>]
    ) -> String {
        var prompt = originalRequest.description

        prompt += "\n\n=== VERIFICATION FEEDBACK ==="
        prompt += "\nPrevious questions failed (score: \(verificationResult.overallScore))."
        prompt += "\n\nREASONS FOR FAILURE:"
        for recommendation in verificationResult.recommendations {
            prompt += "\n- \(recommendation)"
        }

        prompt += "\n\nFAILED QUESTIONS:"
        for question in failedQuestions {
            prompt += "\n- [\(question.category.value)] \(question.question)"
        }

        prompt += "\n\nPlease generate NEW questions addressing these concerns."

        return prompt
    }

    // MARK: - Meta-Learning Helpers

    /// Get adaptive threshold based on historical verification performance
    public func getAdaptiveThreshold(for type: VerificationType) async throws -> Double {
        guard let analyzer = historicalAnalyzer else {
            return type == .questionRelevance
                ? VerificationThresholds.questionVerification
                : VerificationThresholds.prdVerification
        }

        let adaptiveThreshold = try await analyzer.getAdaptiveThreshold(for: type)

        guard adaptiveThreshold.confidence > 0.5 else {
            return type == .questionRelevance
                ? VerificationThresholds.questionVerification
                : VerificationThresholds.prdVerification
        }

        return adaptiveThreshold.threshold
    }

    /// Determine if refinement is historically worthwhile
    public func shouldAttemptRefinement(
        entityType: VerificationEntityType,
        currentAttempt: Int
    ) async throws -> RefinementRecommendation {
        guard let analyzer = historicalAnalyzer else {
            return RefinementRecommendation(
                shouldRefine: currentAttempt < VerificationThresholds.maxRefinementAttempts,
                reason: "No historical data available",
                maxAttempts: VerificationThresholds.maxRefinementAttempts
            )
        }

        return try await analyzer.shouldAttemptRefinement(
            for: entityType,
            currentAttempt: currentAttempt
        )
    }
}
