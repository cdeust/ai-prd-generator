import Foundation
import Domain

/// Service to generate verification questions for Chain of Verification (Step 2)
/// Uses LLM to create fact-checking questions for a given response
/// Following Single Responsibility: Only generates verification questions
public actor VerificationQuestionGeneratorService {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Generate verification questions for a response
    /// - Parameters:
    ///   - originalRequest: Original user request/requirement
    ///   - response: Response to verify
    ///   - maxQuestions: Maximum number of questions to generate
    /// - Returns: Array of verification questions
    /// - Throws: AIProviderError if generation fails
    public func generateQuestions(
        originalRequest: String,
        response: String,
        maxQuestions: Int = 5
    ) async throws -> [VerificationQuestion] {
        let prompt = buildVerificationPrompt(
            originalRequest: originalRequest,
            response: response,
            maxQuestions: maxQuestions
        )

        let result = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.3
        )

        return parseVerificationQuestions(from: result)
    }

    private func buildVerificationPrompt(
        originalRequest: String,
        response: String,
        maxQuestions: Int
    ) -> String {
        """
        You are a verification specialist. Your task is to generate fact-checking questions \
        to verify if a response adequately addresses the original request.

        ORIGINAL REQUEST:
        \(originalRequest)

        RESPONSE TO VERIFY:
        \(response)

        Generate \(maxQuestions) verification questions to check:
        1. Factual accuracy - Is the information correct?
        2. Completeness - Does it fully address the request?
        3. Consistency - Is it internally consistent?
        4. Relevance - Is it relevant to the request?
        5. Clarity - Is it clear and unambiguous?

        Format each question as:
        [CATEGORY] Question text (PRIORITY: 1-100)

        Categories: FACTUAL_ACCURACY, COMPLETENESS, CONSISTENCY, RELEVANCE, CLARITY
        Priority: 100 = critical, 50 = important, 1 = optional

        Example:
        [COMPLETENESS] Does the response address all key requirements mentioned in the request? (PRIORITY: 95)
        [FACTUAL_ACCURACY] Are the technical specifications mentioned in the response accurate? (PRIORITY: 90)

        Generate \(maxQuestions) verification questions now:
        """
    }

    private func parseVerificationQuestions(from response: String) -> [VerificationQuestion] {
        let lines = response
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.hasPrefix("[") }

        return lines.compactMap { line in
            parseQuestionLine(line)
        }
    }

    private func parseQuestionLine(_ line: String) -> VerificationQuestion? {
        let pattern = #"\[(.*?)\]\s*(.*?)\s*\(PRIORITY:\s*(\d+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: line,
                range: NSRange(line.startIndex..., in: line)
              ) else {
            return nil
        }

        guard let categoryRange = Range(match.range(at: 1), in: line),
              let questionRange = Range(match.range(at: 2), in: line),
              let priorityRange = Range(match.range(at: 3), in: line) else {
            return nil
        }

        let categoryStr = String(line[categoryRange]).lowercased()
        let questionText = String(line[questionRange])
        let priorityStr = String(line[priorityRange])

        guard let priority = Int(priorityStr) else {
            return nil
        }

        let category = mapToCategory(categoryStr)

        return VerificationQuestion(
            question: questionText,
            category: category,
            priority: priority
        )
    }

    private func mapToCategory(_ categoryStr: String) -> VerificationCategory {
        switch categoryStr {
        case "factual_accuracy":
            return .factualAccuracy
        case "completeness":
            return .completeness
        case "consistency":
            return .consistency
        case "relevance":
            return .relevance
        case "clarity":
            return .clarity
        default:
            return .factualAccuracy
        }
    }
}
