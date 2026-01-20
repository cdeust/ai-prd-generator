import Foundation

/// Generic clarification session with type parameters
///
/// Professional generic design - analysis types are parameterized.
public struct ClarificationSession<CT, PT, GT>: Sendable, Codable, Identifiable
    where CT: Hashable & Codable & Sendable,
          PT: Comparable & Codable & Sendable & Hashable,
          GT: Hashable & Codable & Sendable
{
    public let id: UUID
    public let userId: UUID
    public let title: String
    public let description: String
    public let currentAnalysis: GapAnalysisResult<CT, PT, GT>
    public let answers: [UUID: String]
    public let round: Int
    public let createdAt: Date
    public let codebaseId: UUID?
    public let verificationResult: CoVVerificationResult?
    public let refinementAttempts: Int

    public init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        description: String,
        currentAnalysis: GapAnalysisResult<CT, PT, GT>,
        answers: [UUID: String] = [:],
        round: Int = 1,
        createdAt: Date = Date(),
        codebaseId: UUID? = nil,
        verificationResult: CoVVerificationResult? = nil,
        refinementAttempts: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.currentAnalysis = currentAnalysis
        self.answers = answers
        self.round = round
        self.createdAt = createdAt
        self.codebaseId = codebaseId
        self.verificationResult = verificationResult
        self.refinementAttempts = refinementAttempts
    }

    /// Get unanswered questions
    public func unansweredQuestions() -> [ClarificationQuestion<CT, PT, GT>] {
        currentAnalysis.questions.filter { question in
            answers[question.id] == nil
        }
    }

    /// Get next question to ask (highest priority unanswered)
    public func nextQuestion() -> ClarificationQuestion<CT, PT, GT>? {
        unansweredQuestions().max(by: { $0.priority < $1.priority })
    }

    /// Calculate progress (0-1)
    public func progress() -> Double {
        guard !currentAnalysis.questions.isEmpty else { return 1.0 }
        return Double(answers.count) / Double(currentAnalysis.questions.count)
    }

    /// Create updated session with new answer
    public func withAnswer(questionId: UUID, answer: String) -> ClarificationSession<CT, PT, GT> {
        var updatedAnswers = answers
        updatedAnswers[questionId] = answer

        return ClarificationSession(
            id: id,
            userId: userId,
            title: title,
            description: description,
            currentAnalysis: currentAnalysis,
            answers: updatedAnswers,
            round: round,
            createdAt: createdAt,
            codebaseId: codebaseId,
            verificationResult: verificationResult,
            refinementAttempts: refinementAttempts
        )
    }

    /// Create updated session with new analysis
    public func withNewAnalysis(_ analysis: GapAnalysisResult<CT, PT, GT>) -> ClarificationSession<CT, PT, GT> {
        ClarificationSession(
            id: id,
            userId: userId,
            title: title,
            description: description,
            currentAnalysis: analysis,
            answers: answers,
            round: round + 1,
            createdAt: createdAt,
            codebaseId: codebaseId,
            verificationResult: nil,
            refinementAttempts: 0
        )
    }

    /// Create updated session with verification result
    public func withVerificationResult(
        _ result: CoVVerificationResult
    ) -> ClarificationSession<CT, PT, GT> {
        ClarificationSession(
            id: id,
            userId: userId,
            title: title,
            description: description,
            currentAnalysis: currentAnalysis,
            answers: answers,
            round: round,
            createdAt: createdAt,
            codebaseId: codebaseId,
            verificationResult: result,
            refinementAttempts: refinementAttempts
        )
    }

    /// Create updated session with refined analysis and incremented attempts
    public func withRefinedAnalysis(
        _ analysis: GapAnalysisResult<CT, PT, GT>,
        verificationResult: CoVVerificationResult
    ) -> ClarificationSession<CT, PT, GT> {
        ClarificationSession(
            id: id,
            userId: userId,
            title: title,
            description: description,
            currentAnalysis: analysis,
            answers: answers,
            round: round,
            createdAt: createdAt,
            codebaseId: codebaseId,
            verificationResult: verificationResult,
            refinementAttempts: refinementAttempts + 1
        )
    }
}
