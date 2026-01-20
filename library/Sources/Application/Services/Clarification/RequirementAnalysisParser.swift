import Foundation
import Domain

/// Parses AI responses for requirement gap analysis
///
/// Extracted for reusability and testability (3R's principle).
/// Handles structured text parsing with error recovery.
public struct RequirementAnalysisParser {
    public init() {}

    /// Parse AI response into gap analysis result
    ///
    /// - Parameters:
    ///   - response: Raw AI response text
    ///   - request: Original PRD request (for context)
    /// - Returns: Parsed gap analysis result
    /// - Throws: RequirementAnalyzerError if parsing fails completely
    public func parse(
        _ response: String,
        request: PRDRequest
    ) throws -> GapAnalysisResult<String, Int, String> {
        // Log raw response for debugging
        print("[DEBUG] AI Response length: \(response.count) characters")
        print("[DEBUG] AI Response preview: \(response.prefix(200))...")

        let completenessScore = extractCompletenessScore(response)
        let confidence = extractConfidence(response)
        let questions = try extractQuestions(response)

        print("[DEBUG] Parsed: completeness=\(completenessScore), confidence=\(confidence), questions=\(questions.count)")

        let gaps = questions.map { $0.detectedGap }

        return GapAnalysisResult(
            completenessScore: completenessScore,
            detectedGaps: gaps,
            questions: questions,
            confidence: confidence
        )
    }

    private func extractCompletenessScore(_ response: String) -> Double {
        let pattern = #"COMPLETENESS_SCORE:\s*([0-9]*\.?[0-9]+)"#
        guard let match = response.range(of: pattern, options: .regularExpression) else {
            print("[WARNING] Could not find COMPLETENESS_SCORE in AI response, defaulting to 0.5")
            return 0.5
        }

        let matchedText = response[match]
        let scoreText = matchedText
            .components(separatedBy: ":")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "0.5"

        let score = Double(scoreText) ?? 0.5
        print("[DEBUG] Extracted completeness score: \(score)")
        return score
    }

    private func extractConfidence(_ response: String) -> Double {
        let pattern = #"CONFIDENCE:\s*([0-9]*\.?[0-9]+)"#
        guard let match = response.range(of: pattern, options: .regularExpression) else {
            print("[WARNING] Could not find CONFIDENCE in AI response, defaulting to 0.8")
            return 0.8
        }

        let matchedText = response[match]
        let confidenceText = matchedText
            .components(separatedBy: ":")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "0.8"

        let confidence = Double(confidenceText) ?? 0.8
        print("[DEBUG] Extracted confidence: \(confidence)")
        return confidence
    }

    private func extractQuestions(_ response: String) throws -> [ClarificationQuestion<String, Int, String>] {
        var questions: [ClarificationQuestion<String, Int, String>] = []
        var parseErrors: [String] = []

        let questionSections = response.components(separatedBy: "QUESTION_")
            .dropFirst()
            .prefix(5)

        print("[DEBUG] Found \(questionSections.count) question sections in AI response")

        for (index, section) in questionSections.enumerated() {
            do {
                let question = try parseQuestionSection(section)
                questions.append(question)
                print("[DEBUG] Successfully parsed question \(index + 1): \(question.question.prefix(50))...")
            } catch {
                let errorMsg = "Question \(index + 1): \(error.localizedDescription)"
                parseErrors.append(errorMsg)
                print("[ERROR] Failed to parse question \(index + 1): \(error)")
            }
        }

        if questions.isEmpty && !questionSections.isEmpty {
            let errorSummary = parseErrors.joined(separator: "; ")
            throw RequirementAnalyzerError.parsingFailed(
                "No questions could be parsed. Errors: \(errorSummary)"
            )
        }

        if !parseErrors.isEmpty {
            print("[WARNING] \(parseErrors.count) questions failed to parse: \(parseErrors.joined(separator: "; "))")
        }

        return questions
    }

    private func parseQuestionSection(_ section: String) throws -> ClarificationQuestion<String, Int, String> {
        let category = extractField(section, pattern: #"CATEGORY:\s*(\w+)"#) ?? "technical"
        let priorityValue = extractIntField(section, pattern: #"PRIORITY:\s*(\d+)"#) ?? 50
        let gapType = extractField(section, pattern: #"GAP_TYPE:\s*([^\n]+)"#) ?? "unspecified"
        let questionText = extractField(section, pattern: #"QUESTION:\s*([^\n]+)"#) ?? "Please clarify."
        let rationale = extractField(section, pattern: #"RATIONALE:\s*([^\n]+)"#) ?? "Needed for clarity."
        let examplesText = extractField(section, pattern: #"EXAMPLES:\s*([^\n]+)"#) ?? ""

        let examples = examplesText
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return ClarificationQuestion(
            category: QuestionCategory(category),
            question: questionText,
            rationale: rationale,
            examples: examples.isEmpty ? ["Please provide details"] : examples,
            priority: QuestionPriority(priorityValue),
            detectedGap: GapType(gapType)
        )
    }

    private func extractField(_ text: String, pattern: String) -> String? {
        guard let match = text.range(of: pattern, options: .regularExpression) else {
            return nil
        }

        let matchedText = text[match]
        return matchedText
            .components(separatedBy: ":")
            .dropFirst()
            .joined(separator: ":")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractIntField(_ text: String, pattern: String) -> Int? {
        guard let field = extractField(text, pattern: pattern) else {
            return nil
        }
        return Int(field)
    }
}
