import Foundation
import Domain

/// Handles section-specific clarification questions
/// Single Responsibility: Generate and collect clarification questions for sections
struct SectionClarificationCollector: Sendable {
    private let clarificationService: SectionClarificationService?
    private let interactionHandler: UserInteractionPort?
    private let llmTracker: SectionLLMTracker
    private let xmlBuilder = ClarificationXMLBuilder()

    init(
        clarificationService: SectionClarificationService?,
        interactionHandler: UserInteractionPort?,
        llmTracker: SectionLLMTracker
    ) {
        self.clarificationService = clarificationService
        self.interactionHandler = interactionHandler
        self.llmTracker = llmTracker
    }

    func askClarifications(
        prdId: UUID,
        sectionType: SectionType,
        request: PRDRequest,
        previousSections: [PRDSection]
    ) async throws -> String {
        guard let service = clarificationService,
              let handler = interactionHandler else {
            return ""
        }

        let questions = try await service.generateQuestionsForSection(
            sectionType,
            request: request,
            previousSections: previousSections
        )

        guard !questions.isEmpty else {
            return ""
        }

        await handler.notifyProgress("Clarifying \(sectionType.displayName) requirements...")

        var clarifications = ""
        for question in questions.prefix(2) {
            print("❓ [SectionClarification] Asking: \(question.question)")
            if let answer = await handler.askQuestion(question) {
                clarifications += xmlBuilder.buildXML(
                    question: question, answer: answer, section: sectionType.displayName
                )
                print("✅ [SectionClarification] Got answer for \(sectionType.displayName)")
                await llmTracker.trackClarification(
                    prdId: prdId,
                    question: question,
                    answer: answer,
                    sectionType: sectionType
                )
            }
        }
        return clarifications
    }
}
