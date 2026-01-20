import Foundation
import Domain

/// Handles enriching PRD requests with user clarifications
struct ClarificationEnrichment: Sendable {
    private let handler: UserInteractionPort
    private let intelligenceTracker: IntelligenceTrackerService?

    init(handler: UserInteractionPort, intelligenceTracker: IntelligenceTrackerService? = nil) {
        self.handler = handler
        self.intelligenceTracker = intelligenceTracker
    }

    func enrichRequest(
        _ request: PRDRequest,
        questions: [ClarificationQuestion<String, Int, String>]
    ) async throws -> ClarificationEnrichmentResult {
        await handler.notifyProgress("Found \(questions.count) clarification questions")

        guard !questions.isEmpty else {
            return ClarificationEnrichmentResult(request: request, answeredQuestionIds: [], collectedAnswers: [])
        }

        let (enrichedDescription, answeredIds, answers) = await collectAnswers(
            from: questions,
            originalDescription: request.description
        )

        let enrichedRequest = PRDRequest(
            userId: request.userId,
            title: request.title,
            description: enrichedDescription,
            requirements: request.requirements,
            constraints: request.constraints,
            platform: request.platform,
            metadata: request.metadata,
            codebaseId: request.codebaseId,
            templateId: request.templateId
        )

        print("🔍 [DEBUG] ClarificationEnrichment returning:")
        print("   - Answered question IDs count: \(answeredIds.count)")
        print("   - Question IDs: \(answeredIds)")
        print("   - Collected answers count: \(answers.count)")

        return ClarificationEnrichmentResult(
            request: enrichedRequest,
            answeredQuestionIds: answeredIds,
            collectedAnswers: answers
        )
    }

    private func collectAnswers(
        from questions: [ClarificationQuestion<String, Int, String>],
        originalDescription: String
    ) async -> (String, [UUID], [String]) {
        var enrichedDescription = originalDescription
        var answeredQuestionIds: [UUID] = []
        var collectedAnswers: [String] = []
        let sortedQuestions = questions.sorted { $0.priority > $1.priority }

        print("📝 [ClarificationEnrichment] Original description length: \(originalDescription.count) chars")
        print("📝 [ClarificationEnrichment] Processing \(sortedQuestions.prefix(5).count) questions...")

        for (index, question) in sortedQuestions.prefix(5).enumerated() {
            print("❓ [ClarificationEnrichment] Asking question \(index + 1): \(question.question)")
            if let answer = await handler.askQuestion(question) {
                // Format clarification with STRONG XML markers that AI MUST follow
                let enrichment = """


                <clarification category="\(question.category.value)" priority="\(question.priority.value)">
                <question>\(question.question)</question>
                <answer>\(answer)</answer>
                <requirement>You MUST use this clarification when generating the PRD. This is a USER-PROVIDED requirement.</requirement>
                </clarification>
                """
                enrichedDescription += enrichment
                answeredQuestionIds.append(question.id)
                collectedAnswers.append(answer)
                print("✅ [ClarificationEnrichment] Answer received and added (\(answer.count) chars)")

                // Update existing trace with user's answer
                await updateClarificationWithAnswer(question: question, answer: answer)
            } else {
                print("⚠️  [ClarificationEnrichment] No answer received for question \(index + 1)")
            }
        }

        print("✨ [ClarificationEnrichment] Enriched: \(collectedAnswers.count) Q&A pairs")
        return (enrichedDescription, answeredQuestionIds, collectedAnswers)
    }

    /// Update existing trace with user's answer (trace was created in PRDContextService with coherence scores)
    private func updateClarificationWithAnswer(
        question: ClarificationQuestion<String, Int, String>,
        answer: String
    ) async {
        guard let tracker = intelligenceTracker else { return }
        do {
            try await tracker.clarificationTracker.updateAnswerByQuestionId(
                questionId: question.id,
                userAnswer: answer,
                answerTimestamp: Date()
            )
            print("✅ [Intelligence] Updated clarification with answer: \(question.category.value)")
        } catch {
            print("❌ [Intelligence] Failed to update clarification: \(error)")
        }
    }
}
