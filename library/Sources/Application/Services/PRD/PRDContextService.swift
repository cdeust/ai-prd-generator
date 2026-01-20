import Foundation
import Domain

/// Service for building and enriching PRD context
/// Single Responsibility: Handle context enrichment and clarification
struct PRDContextService: Sendable {
    private let contextBuilder: EnrichedContextBuilder?
    private let clarificationEnrichment: ClarificationEnrichment?
    private let requirementAnalyzer: RequirementAnalyzerService?
    private let deduplicator = QuestionDeduplicator()
    private let filterCoordinator: QuestionFilterCoordinator?
    private let verificationCoordinator: QuestionVerificationCoordinator?
    private let trackingService: ClarificationTrackingService?

    init(
        contextBuilder: EnrichedContextBuilder?,
        clarificationEnrichment: ClarificationEnrichment?,
        requirementAnalyzer: RequirementAnalyzerService?,
        coherenceScorer: QuestionCoherenceScorer? = nil,
        intelligenceTracker: IntelligenceTrackerService? = nil,
        verificationService: ChainOfVerificationService? = nil
    ) {
        self.contextBuilder = contextBuilder
        self.clarificationEnrichment = clarificationEnrichment
        self.requirementAnalyzer = requirementAnalyzer

        if let tracker = intelligenceTracker {
            self.trackingService = ClarificationTrackingService(intelligenceTracker: tracker)
        } else {
            self.trackingService = nil
        }

        if let scorer = coherenceScorer {
            self.filterCoordinator = QuestionFilterCoordinator(
                coherenceScorer: scorer,
                trackingService: trackingService
            )
        } else {
            self.filterCoordinator = nil
        }

        if let service = verificationService {
            self.verificationCoordinator = QuestionVerificationCoordinator(verificationService: service)
        } else {
            self.verificationCoordinator = nil
        }
    }

    /// Runs analysis loop: LLM analyzes → generates questions → user answers → re-analyze
    /// - Parameter previousQuestionIds: Question IDs from previous session to load and avoid re-asking
    func enrichRequestWithClarifications(
        _ request: PRDRequest,
        codebaseContext: RAGSearchResults?,
        mockupSummaries: [String] = [],
        previousQuestionIds: [UUID] = []
    ) async throws -> ClarificationEnrichmentResult {
        guard let enrichment = clarificationEnrichment, let analyzer = requirementAnalyzer else {
            return ClarificationEnrichmentResult(request: request, answeredQuestionIds: [], collectedAnswers: [])
        }

        // Load previous clarifications from DB for session continuity
        let previousClarifications = await trackingService?.loadPreviousClarifications(questionIds: previousQuestionIds) ?? []
        var state = ClarificationLoopState(request: request, previousClarifications: previousClarifications)

        while true {
            let roundResult = try await processRound(
                state: state, analyzer: analyzer, enrichment: enrichment,
                codebaseContext: codebaseContext, mockupSummaries: mockupSummaries
            )

            guard let updated = roundResult else { break }
            state = updated
        }

        // Collect all answers from clarifications
        let allAnswers = state.previousClarifications.map { $0.answer }
        return ClarificationEnrichmentResult(
            request: state.request,
            answeredQuestionIds: state.answeredIds,
            collectedAnswers: allAnswers
        )
    }

    func buildEnrichedContext(for request: PRDRequest, prdId: UUID? = nil) async throws -> EnrichedPRDContext? {
        guard let builder = contextBuilder else { return nil }
        print("🧠 Building enriched context (RAG + Reasoning)...")
        let context = try await builder.buildContext(request: request, codebaseId: request.codebaseId, prdId: prdId)
        print("✨ Enriched context ready")
        return context
    }
}

// MARK: - Clarification Loop Processing
extension PRDContextService {

    private func processRound(
        state: ClarificationLoopState,
        analyzer: RequirementAnalyzerService,
        enrichment: ClarificationEnrichment,
        codebaseContext: RAGSearchResults?,
        mockupSummaries: [String]
    ) async throws -> ClarificationLoopState? {
        print("🔄 [Analysis] Round \(state.round) - analyzing...")
        print("📋 [Analysis] Previous clarifications: \(state.previousClarifications.count) Q&A pairs")

        // Convert to tuple format for analyzer
        let clarifications = state.previousClarifications.map { ($0.question, $0.answer) }

        var questions = try await analyzer.analyzeAndGenerateQuestions(
            state.request, codebaseContext: codebaseContext,
            mockupSummaries: mockupSummaries, previousClarifications: clarifications
        )

        if questions.isEmpty {
            print("✅ [Analysis] Complete after \(state.round) round(s)")
            return nil
        }

        // Deduplicate: remove questions similar to previously asked
        questions = deduplicator.deduplicateQuestions(questions, previous: state.previousQuestions)

        if questions.isEmpty {
            print("✅ [Analysis] Complete - all questions were duplicates")
            return nil
        }

        if let filter = filterCoordinator {
            questions = try await filter.filterQuestions(
                questions, request: state.request,
                codebaseContext: codebaseContext, mockupSummaries: mockupSummaries
            )
        } else {
            await trackingService?.trackQuestionsWithoutScoring(questions)
        }

        if questions.isEmpty {
            print("✅ [Analysis] Complete - all questions filtered as low-value")
            return nil
        }

        // Verify questions with multiple judges if verification service available
        if let verifier = verificationCoordinator {
            print("🔍 [PRDContext] About to verify \(questions.count) questions with verification service")
            questions = try await verifier.verifyQuestions(questions, request: state.request)
            print("🔍 [PRDContext] After verification: \(questions.count) questions remain")
        } else {
            print("⚠️ [Verification] No verification service configured - skipping judge evaluation")
        }

        if questions.isEmpty {
            print("✅ [Analysis] Complete - all questions failed verification")
            return nil
        }

        let result = try await enrichment.enrichRequest(state.request, questions: questions)

        // Track effectiveness of this round's clarifications
        await trackingService?.trackRoundEffectiveness(answeredQuestionIds: result.answeredQuestionIds)

        return state.updated(with: result, askedQuestions: questions, answers: result.collectedAnswers)
    }
}

