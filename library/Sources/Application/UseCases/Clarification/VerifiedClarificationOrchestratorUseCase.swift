import Foundation
import Domain

/// Enhanced clarification orchestrator with Chain of Verification + Meta-Learning
/// Implements COMPLETE 4-step CoV pattern with refinement loop (Step 4)
/// Following Open/Closed: Extends without modifying original orchestrator
/// FIXED: Verification results now USED to refine questions, not discarded
/// META-LEARNING: Uses historical verification data to improve accuracy exponentially
public actor VerifiedClarificationOrchestratorUseCase {
    private let baseOrchestrator: ClarificationOrchestratorUseCase
    private let verificationService: ChainOfVerificationService
    private let refinementCoordinator: ClarificationRefinementCoordinator
    private let formatter: VerificationContextFormatter
    private let enableVerification: Bool

    public init(
        baseOrchestrator: ClarificationOrchestratorUseCase,
        verificationService: ChainOfVerificationService,
        analyzer: RequirementAnalyzerService,
        historicalAnalyzer: HistoricalVerificationAnalyzer? = nil,
        evidenceRepository: VerificationEvidenceRepositoryPort? = nil,
        enableVerification: Bool = true
    ) {
        self.baseOrchestrator = baseOrchestrator
        self.verificationService = verificationService
        self.refinementCoordinator = ClarificationRefinementCoordinator(
            analyzer: analyzer,
            verificationService: verificationService,
            historicalAnalyzer: historicalAnalyzer,
            evidenceRepository: evidenceRepository
        )
        self.formatter = VerificationContextFormatter()
        self.enableVerification = enableVerification
    }

    /// Start clarification with COMPLETE verification (includes refinement)
    /// CoV Steps 1-4: Generate → Verify → Judge → Refine ✅
    /// META-LEARNING: Uses adaptive thresholds and stores evidence
    public func startClarification(
        initialRequest: PRDRequest
    ) async throws -> ClarificationSession<String, Int, String> {
        var session = try await baseOrchestrator.startClarification(
            initialRequest: initialRequest
        )

        guard enableVerification,
              !session.currentAnalysis.questions.isEmpty else {
            return session
        }

        // META-LEARNING: Get adaptive threshold from historical data
        let threshold = try await refinementCoordinator.getAdaptiveThreshold(for: .questionRelevance)

        let verificationResult = try await verifyQuestions(
            session.currentAnalysis.questions,
            originalRequest: initialRequest.description,
            threshold: threshold,
            sessionId: session.id
        )

        session = session.withVerificationResult(verificationResult)

        if !verificationResult.verified {
            let refined = try await refinementCoordinator.refineQuestions(
                session: session,
                verificationResult: verificationResult,
                originalRequest: initialRequest,
                verifyQuestionsCallback: verifyQuestions
            )
            session = refined.session
        }

        return session
    }

    /// Submit answer with clarification-aware PRD verification
    public func submitAnswer(
        session: ClarificationSession<String, Int, String>,
        questionId: UUID,
        answer: String,
        userWantsToProceed: Bool = false
    ) async throws -> VerifiedClarificationResult {
        let result = try await baseOrchestrator.submitAnswer(
            session: session,
            questionId: questionId,
            answer: answer,
            userWantsToProceed: userWantsToProceed
        )

        switch result {
        case .complete(let document):
            guard enableVerification else {
                return .complete(document, verificationResult: nil)
            }

            let verificationResult = try await verifyPRDDocument(
                document: document,
                session: session
            )

            return .complete(document, verificationResult: verificationResult)

        case .continueWithQuestions(let updatedSession):
            return .continueWithQuestions(updatedSession)

        case .readyToComplete(let updatedSession, let completeness):
            return .readyToComplete(updatedSession, currentCompleteness: completeness)
        }
    }


    private func verifyQuestions(
        _ questions: [ClarificationQuestion<String, Int, String>],
        originalRequest: String,
        threshold: Double? = nil,
        sessionId: UUID? = nil
    ) async throws -> CoVVerificationResult {
        let questionsText = formatter.formatQuestionsForVerification(questions)

        let verificationThreshold = threshold ?? VerificationThresholds.questionVerification

        return try await verificationService.verify(
            originalRequest: originalRequest,
            response: questionsText,
            verificationThreshold: verificationThreshold,
            entityType: sessionId != nil ? .clarificationSession : nil,
            entityId: sessionId,
            verificationType: .questionRelevance
        )
    }


    private func verifyPRDDocument(
        document: PRDDocument,
        session: ClarificationSession<String, Int, String>
    ) async throws -> CoVVerificationResult {
        let prdText = formatter.formatPRDForVerification(document)

        let enrichedContext = formatter.buildEnrichedVerificationContext(
            originalRequest: session.description,
            clarifications: session.answers,
            questions: session.currentAnalysis.questions
        )

        // META-LEARNING: Use adaptive threshold for PRD verification
        let threshold = try await refinementCoordinator.getAdaptiveThreshold(for: .prdQuality)

        let verificationResult = try await verificationService.verify(
            originalRequest: enrichedContext,
            response: prdText,
            verificationThreshold: threshold,
            entityType: .prdDocument,
            entityId: document.id,
            verificationType: .prdQuality
        )

        return verificationResult
    }
}
