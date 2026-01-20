import Foundation
import Domain

/// Use case for Phase 1 analysis of a PRD request
///
/// Performs real analysis including:
/// - Building enriched context (RAG from codebase, vision from mockups)
/// - Generating clarification questions using AI
/// - Tracking all analysis in intelligence tables
///
/// Returns a ClarificationSession with questions for the user to answer
public struct AnalyzeRequestUseCase: Sendable {
    private let contextBuilder: EnrichedContextBuilder?
    private let requirementAnalyzer: RequirementAnalyzerService
    private let intelligenceTracker: IntelligenceTrackerService?

    public init(
        contextBuilder: EnrichedContextBuilder?,
        requirementAnalyzer: RequirementAnalyzerService,
        intelligenceTracker: IntelligenceTrackerService?
    ) {
        self.contextBuilder = contextBuilder
        self.requirementAnalyzer = requirementAnalyzer
        self.intelligenceTracker = intelligenceTracker
    }

    /// Execute Phase 1 analysis
    ///
    /// - Parameter request: The PRD request to analyze
    /// - Returns: Analysis result with enriched context and clarification session
    public func execute(_ request: PRDRequest) async throws -> AnalysisResult {
        print("🔬 [Phase 1] Starting analysis for: \(request.title)")

        // Start tracking this analysis session
        intelligenceTracker?.startGeneration()

        // 1. Build enriched context (RAG + vision + reasoning)
        let enrichedContext = try await buildEnrichedContext(for: request)

        // 2. Generate clarification questions using the context
        let gapAnalysis = try await analyzeRequirements(
            request: request,
            codebaseContext: enrichedContext?.ragResults
        )

        print("📊 [Phase 1] Analysis complete:")
        print("  - RAG results: \(enrichedContext?.ragResults?.relevantFiles.count ?? 0) files")
        print("  - Vision results: \(enrichedContext?.visionResults?.count ?? 0) mockups")
        print("  - Clarification questions: \(gapAnalysis.questions.count)")
        print("  - Completeness score: \(gapAnalysis.completenessScore)")

        // 3. Create session with questions
        let session = ClarificationSession(
            userId: request.userId,
            title: request.title,
            description: request.description,
            currentAnalysis: gapAnalysis,
            answers: [:],
            codebaseId: request.codebaseId
        )

        return AnalysisResult(
            session: session,
            enrichedContext: enrichedContext,
            hasQuestions: !gapAnalysis.questions.isEmpty
        )
    }

    private func buildEnrichedContext(for request: PRDRequest) async throws -> EnrichedPRDContext? {
        guard let builder = contextBuilder else {
            print("⚠️ [Phase 1] No context builder available, skipping RAG/vision")
            return nil
        }

        print("🧠 [Phase 1] Building enriched context (RAG + Vision + Reasoning)...")
        let context = try await builder.buildContext(
            request: request,
            codebaseId: request.codebaseId,
            prdId: nil  // PRD doesn't exist yet in Phase 1
        )
        print("✨ [Phase 1] Enriched context ready")
        return context
    }

    private func analyzeRequirements(
        request: PRDRequest,
        codebaseContext: RAGSearchResults?
    ) async throws -> GapAnalysisResult<String, Int, String> {
        print("❓ [Phase 1] Generating clarification questions...")
        let analysis = try await requirementAnalyzer.analyzeRequirements(
            request,
            codebaseContext: codebaseContext
        )

        // Track clarification questions in intelligence layer
        await trackClarificationQuestions(analysis: analysis)

        return analysis
    }

    private func trackClarificationQuestions(
        analysis: GapAnalysisResult<String, Int, String>
    ) async {
        guard let tracker = intelligenceTracker, !analysis.questions.isEmpty else { return }

        for question in analysis.questions {
            do {
                _ = try await tracker.trackClarification(
                    prdId: nil,  // PRD doesn't exist yet
                    questionId: question.id,
                    questionText: question.question,
                    reasoningForAsking: question.rationale,
                    gapAddressed: question.category.value,
                    userAnswer: nil,  // Not answered yet
                    answerTimestamp: nil
                )
            } catch {
                print("❌ [Intelligence] Failed to track question: \(error)")
            }
        }
        print("✅ [Intelligence] Tracked \(analysis.questions.count) clarification questions")
    }
}
