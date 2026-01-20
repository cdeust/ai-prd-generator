import Foundation
import Domain

/// State for the clarification question loop
/// Tracks current request, answered question IDs, and round number
struct ClarificationLoopState: Sendable {
    var request: PRDRequest
    var answeredIds: [UUID] = []
    var previousClarifications: [ClarificationQAPair] = []
    var round: Int = 1

    init(request: PRDRequest, previousClarifications: [ClarificationQAPair] = []) {
        self.request = request
        self.previousClarifications = previousClarifications
        self.answeredIds = []
        self.round = 1
    }

    /// For backward compatibility - just the question texts
    var previousQuestions: [String] {
        previousClarifications.map { $0.question }
    }

    func updated(
        with result: ClarificationEnrichmentResult,
        askedQuestions: [ClarificationQuestion<String, Int, String>],
        answers: [String]
    ) -> ClarificationLoopState {
        var copy = self
        copy.request = result.request
        copy.answeredIds.append(contentsOf: result.answeredQuestionIds)

        // Store Q&A pairs, not just questions
        for (question, answer) in zip(askedQuestions, answers) {
            copy.previousClarifications.append(ClarificationQAPair(
                question: question.question,
                answer: answer
            ))
        }

        copy.round += 1
        return copy
    }
}
