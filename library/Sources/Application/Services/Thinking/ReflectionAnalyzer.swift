import Foundation
import Domain

/// Analyzes reasoning attempts and provides reflection
/// Single Responsibility: Evaluate attempt quality and suggest improvements
public struct ReflectionAnalyzer: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Reflect on reasoning attempt
    public func reflect(
        on attempt: ThoughtChain,
        problem: String,
        context: String,
        iteration: Int
    ) async throws -> ReflectionEntry {
        let prompt = buildReflectionPrompt(
            attempt: attempt,
            problem: problem,
            context: context
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.3
        )

        return parseReflection(
            response: response,
            iteration: iteration,
            attempt: attempt
        )
    }

    // MARK: - Private Methods

    private func buildReflectionPrompt(
        attempt: ThoughtChain,
        problem: String,
        context: String
    ) -> String {
        """
        Critically evaluate this solution attempt:

        <problem>
        \(problem)
        </problem>

        <attempt>
        Thoughts: \(attempt.thoughts.map(\.content).joined(separator: "\n"))
        Conclusion: \(attempt.conclusion)
        Confidence: \(attempt.confidence)
        </attempt>

        <context>
        \(context)
        </context>

        Provide:
        1. QUALITY_SCORE: Overall quality (0.0-1.0)
        2. STRENGTHS: What was done well (3-5 points)
        3. WEAKNESSES: What needs improvement (3-5 points)
        4. IMPROVEMENTS: Specific actionable improvements (3-5 points)

        Be honest and constructive. Focus on logical soundness and alignment with context.
        """
    }

    private func parseReflection(
        response: String,
        iteration: Int,
        attempt: ThoughtChain
    ) -> ReflectionEntry {
        let lines = response.components(separatedBy: "\n")
        var qualityScore = 0.5
        var strengths: [String] = []
        var weaknesses: [String] = []
        var improvements: [String] = []
        var currentSection = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.starts(with: "QUALITY_SCORE:") {
                qualityScore = parseQualityScore(from: trimmed)
            } else if trimmed.starts(with: "STRENGTHS:") {
                currentSection = "strengths"
            } else if trimmed.starts(with: "WEAKNESSES:") {
                currentSection = "weaknesses"
            } else if trimmed.starts(with: "IMPROVEMENTS:") {
                currentSection = "improvements"
            } else if isBulletPoint(trimmed) {
                let result = addToSection(
                    trimmed,
                    section: currentSection,
                    strengths: strengths,
                    weaknesses: weaknesses,
                    improvements: improvements
                )
                strengths = result.strengths
                weaknesses = result.weaknesses
                improvements = result.improvements
            }
        }

        return ReflectionEntry(
            id: UUID(),
            iteration: iteration,
            attempt: attempt,
            qualityScore: qualityScore,
            strengths: strengths.isEmpty ? ["Attempted solution"] : strengths,
            weaknesses: weaknesses.isEmpty ? ["Needs refinement"] : weaknesses,
            suggestedImprovements: improvements.isEmpty ? ["Refine approach"] : improvements,
            timestamp: Date()
        )
    }

    private func parseQualityScore(from line: String) -> Double {
        let scoreStr = line.replacingOccurrences(of: "QUALITY_SCORE:", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(scoreStr) ?? 0.5
    }

    private func isBulletPoint(_ line: String) -> Bool {
        line.starts(with: "-") || line.first?.isNumber == true
    }

    private func addToSection(
        _ line: String,
        section: String,
        strengths: [String],
        weaknesses: [String],
        improvements: [String]
    ) -> (strengths: [String], weaknesses: [String], improvements: [String]) {
        let cleaned = line
            .replacingOccurrences(of: "^[0-9]+\\.", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^-", with: "")
            .trimmingCharacters(in: .whitespaces)

        var newStrengths = strengths
        var newWeaknesses = weaknesses
        var newImprovements = improvements

        if !cleaned.isEmpty {
            switch section {
            case "strengths": newStrengths.append(cleaned)
            case "weaknesses": newWeaknesses.append(cleaned)
            case "improvements": newImprovements.append(cleaned)
            default: break
            }
        }

        return (newStrengths, newWeaknesses, newImprovements)
    }
}
