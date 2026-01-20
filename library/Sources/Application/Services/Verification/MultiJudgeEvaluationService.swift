import Foundation
import Domain

/// Service to evaluate responses using multiple LLM judges
/// Part of LLM-as-a-Judge pattern - coordinates parallel evaluation
/// Following Single Responsibility: Only coordinates judge evaluations
public actor MultiJudgeEvaluationService {
    private let judges: [AIProviderPort]

    public init(judges: [AIProviderPort]) {
        self.judges = judges
    }

    /// Evaluate a response against a verification question using multiple judges
    /// Judges evaluate independently to avoid bias
    /// - Parameters:
    ///   - question: Verification question to evaluate
    ///   - originalRequest: Original user request
    ///   - response: Response being verified
    /// - Returns: Array of judgment scores from each judge
    /// - Throws: AIProviderError if evaluation fails
    public func evaluateWithJudges(
        question: VerificationQuestion,
        originalRequest: String,
        response: String
    ) async throws -> [JudgmentScore] {
        try await withThrowingTaskGroup(of: JudgmentScore.self) { group in
            for judge in judges {
                group.addTask {
                    try await self.evaluateWithSingleJudge(
                        judge: judge,
                        question: question,
                        originalRequest: originalRequest,
                        response: response
                    )
                }
            }

            var scores: [JudgmentScore] = []
            for try await score in group {
                scores.append(score)
            }

            return scores
        }
    }

    private func evaluateWithSingleJudge(
        judge: AIProviderPort,
        question: VerificationQuestion,
        originalRequest: String,
        response: String
    ) async throws -> JudgmentScore {
        let prompt = buildJudgePrompt(
            question: question,
            originalRequest: originalRequest,
            response: response
        )

        let result = try await judge.generateText(
            prompt: prompt,
            temperature: 0.1
        )

        return try parseJudgmentScore(
            from: result,
            judge: judge,
            questionId: question.id
        )
    }

    private func buildJudgePrompt(
        question: VerificationQuestion,
        originalRequest: String,
        response: String
    ) -> String {
        """
        You are an impartial judge evaluating if a response adequately addresses a verification question.

        ORIGINAL REQUEST:
        \(originalRequest)

        RESPONSE TO EVALUATE:
        \(response)

        VERIFICATION QUESTION (\(question.category.rawValue)):
        \(question.question)

        Evaluate the response and provide your judgment in this EXACT format:

        SCORE: [0.0-1.0]
        CONFIDENCE: [0.0-1.0]
        REASONING: [Your reasoning in 1-2 sentences]

        Guidelines:
        - SCORE: 0.0 = completely fails, 1.0 = perfectly addresses
        - CONFIDENCE: How confident you are in your score (0.0 = uncertain, 1.0 = very confident)
        - REASONING: Brief explanation of your score

        Example:
        SCORE: 0.85
        CONFIDENCE: 0.90
        REASONING: The response addresses most key points but lacks specific technical details mentioned in the request.

        Provide your evaluation now:
        """
    }

    private func parseJudgmentScore(
        from response: String,
        judge: AIProviderPort,
        questionId: UUID
    ) throws -> JudgmentScore {
        let lines = response
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var score: Double?
        var confidence: Double?
        var reasoning: String?

        for line in lines {
            if line.hasPrefix("SCORE:") {
                let scoreStr = line.replacingOccurrences(of: "SCORE:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                score = Double(scoreStr)
            } else if line.hasPrefix("CONFIDENCE:") {
                let confStr = line.replacingOccurrences(of: "CONFIDENCE:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                confidence = Double(confStr)
            } else if line.hasPrefix("REASONING:") {
                reasoning = line.replacingOccurrences(of: "REASONING:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        guard let finalScore = score,
              let finalConfidence = confidence,
              let finalReasoning = reasoning else {
            throw AIProviderError.generationFailed(
                "Failed to parse judgment score from response"
            )
        }

        return JudgmentScore(
            judgeProvider: judge.providerName,
            judgeModel: judge.modelName,
            score: finalScore,
            confidence: finalConfidence,
            reasoning: finalReasoning,
            verificationQuestionId: questionId
        )
    }
}
