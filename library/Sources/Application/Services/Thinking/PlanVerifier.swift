import Foundation
import Domain

/// Verifies plan execution completeness
/// Single Responsibility: Validate plan results against original problem
public struct PlanVerifier: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Verify if plan execution solved the problem
    public func verify(
        problem: String,
        plan: ExecutionPlan,
        results: [StepResult],
        context: String
    ) async throws -> PlanVerification {
        let prompt = buildVerificationPrompt(
            problem: problem,
            plan: plan,
            results: results,
            context: context
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.2
        )

        return parseVerification(response: response)
    }

    // MARK: - Private Methods

    private func buildVerificationPrompt(
        problem: String,
        plan: ExecutionPlan,
        results: [StepResult],
        context: String
    ) -> String {
        let executionSummary = results.map { result in
            "Step \(result.stepNumber): \(result.output)"
        }.joined(separator: "\n")

        return """
        Verify if the plan execution solved the original problem:

        <original_problem>
        \(problem)
        </original_problem>

        <execution_summary>
        \(executionSummary)
        </execution_summary>

        <context>
        \(context)
        </context>

        Provide:
        IS_COMPLETE: [yes|no]
        COMPLETENESS_SCORE: [0.0-1.0]
        GAPS: [any missing pieces]
        RECOMMENDATIONS: [improvements if needed]
        """
    }

    private func parseVerification(response: String) -> PlanVerification {
        let lines = response.components(separatedBy: "\n")
        var isComplete = false
        var completenessScore = 0.0
        var gaps: [String] = []
        var recommendations: [String] = []
        var currentSection = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.starts(with: "IS_COMPLETE:") {
                isComplete = parseCompleteness(from: trimmed)
            } else if trimmed.starts(with: "COMPLETENESS_SCORE:") {
                completenessScore = parseScore(from: trimmed)
            } else if trimmed.starts(with: "GAPS:") {
                currentSection = "gaps"
                gaps = appendNonEmpty(trimmed, prefix: "GAPS:", to: gaps)
            } else if trimmed.starts(with: "RECOMMENDATIONS:") {
                currentSection = "recommendations"
                recommendations = appendNonEmpty(trimmed, prefix: "RECOMMENDATIONS:", to: recommendations)
            } else if trimmed.starts(with: "-") {
                let result = appendBulletPoint(trimmed, section: currentSection, gaps: gaps, recommendations: recommendations)
                gaps = result.gaps
                recommendations = result.recommendations
            }
        }

        return PlanVerification(
            isComplete: isComplete,
            completenessScore: completenessScore,
            identifiedGaps: gaps,
            recommendations: recommendations
        )
    }

    private func parseCompleteness(from line: String) -> Bool {
        let value = extractValue(from: line, prefix: "IS_COMPLETE:")
        return value.lowercased().contains("yes")
    }

    private func parseScore(from line: String) -> Double {
        let scoreStr = extractValue(from: line, prefix: "COMPLETENESS_SCORE:")
        return Double(scoreStr) ?? 0.0
    }

    private func extractValue(from line: String, prefix: String) -> String {
        line.replacingOccurrences(of: prefix, with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func appendNonEmpty(_ line: String, prefix: String, to array: [String]) -> [String] {
        let value = extractValue(from: line, prefix: prefix)
        if !value.isEmpty && value.lowercased() != "none" {
            var newArray = array
            newArray.append(value)
            return newArray
        }
        return array
    }

    private func appendBulletPoint(
        _ line: String,
        section: String,
        gaps: [String],
        recommendations: [String]
    ) -> (gaps: [String], recommendations: [String]) {
        let cleaned = line.replacingOccurrences(of: "^-", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        var newGaps = gaps
        var newRecommendations = recommendations

        if !cleaned.isEmpty {
            if section == "gaps" {
                newGaps.append(cleaned)
            } else if section == "recommendations" {
                newRecommendations.append(cleaned)
            }
        }

        return (newGaps, newRecommendations)
    }
}
