import Foundation
import Domain

/// Self-Consistency: Sample multiple reasoning paths, take majority vote
/// Single Responsibility: Execute self-consistency reasoning
///
/// **Strategy:** Generate multiple independent solutions to the same problem,
/// then aggregate them (majority vote or consensus) for a more robust answer.
///
/// **Best for:**
/// - Problems with discrete answers
/// - When accuracy is critical
/// - Tasks where multiple valid approaches exist
public struct SelfConsistencyUseCase: Sendable {
    private let aiProvider: AIProviderPort
    private let sampleCount: Int

    public init(aiProvider: AIProviderPort, sampleCount: Int = 5) {
        self.aiProvider = aiProvider
        self.sampleCount = sampleCount
    }

    public func execute(
        problem: String,
        context: String,
        taskInstructions: String
    ) async throws -> SelfConsistencyResult {
        // Generate multiple reasoning paths independently
        var reasoningPaths: [ReasoningPath] = []

        for index in 0..<sampleCount {
            let prompt = buildReasoningPrompt(
                problem: problem,
                context: context,
                instructions: taskInstructions,
                variation: index
            )

            let response = try await aiProvider.generateText(prompt: prompt, temperature: 0.7)
            let extracted = extractAnswer(from: response)

            reasoningPaths.append(ReasoningPath(
                reasoning: response,
                answer: extracted.answer,
                confidence: extracted.confidence
            ))
        }

        // Aggregate answers using majority vote
        let consensus = findConsensus(paths: reasoningPaths)

        return SelfConsistencyResult(
            solution: consensus.answer,
            reasoning: consensus.supportingReasoning,
            pathsGenerated: reasoningPaths.count,
            agreementScore: consensus.agreement,
            confidence: consensus.confidence,
            allPaths: reasoningPaths
        )
    }

    private func buildReasoningPrompt(
        problem: String,
        context: String,
        instructions: String,
        variation: Int
    ) -> String {
        // Slight variations to encourage diversity
        let diversity = [
            "Think through this carefully:",
            "Consider different approaches:",
            "Analyze this systematically:",
            "Break this down step by step:",
            "Reason about this problem:"
        ]

        return """
        <task>
        \(instructions)
        </task>

        <context>
        \(context)
        </context>

        <problem>
        \(problem)
        </problem>

        <instructions>
        \(diversity[variation % diversity.count])
        - Show your reasoning clearly
        - Arrive at a specific answer
        - State your conclusion at the end with "Answer: [your answer]"
        </instructions>
        """
    }

    private func extractAnswer(from response: String) -> (answer: String, confidence: Double) {
        // Extract answer from "Answer: X" format
        if let range = response.range(of: "Answer:", options: .caseInsensitive) {
            let remainder = response[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            let lines = remainder.components(separatedBy: .newlines)
            let answer = lines.first?.trimmingCharacters(in: .whitespaces) ?? remainder

            // Estimate confidence from certainty markers
            let hasUncertainty = response.lowercased().contains("uncertain") ||
                                response.lowercased().contains("not sure") ||
                                response.lowercased().contains("might")
            return (answer, hasUncertainty ? 0.60 : 0.80)
        }

        // Fallback: use last non-empty line
        let lines = response.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return (lines.last ?? response, 0.50)
    }

    private func findConsensus(paths: [ReasoningPath]) -> ConsensusResult {
        // Count occurrences of each answer
        var answerCounts: [String: Int] = [:]
        var answerPaths: [String: [ReasoningPath]] = [:]

        for path in paths {
            let normalized = path.answer.lowercased().trimmingCharacters(in: .whitespaces)
            answerCounts[normalized, default: 0] += 1
            answerPaths[normalized, default: []].append(path)
        }

        // Find most common answer
        guard let (consensusAnswer, count) = answerCounts.max(by: { $0.value < $1.value }) else {
            return ConsensusResult(
                answer: paths.first?.answer ?? "",
                supportingReasoning: paths.first?.reasoning ?? "",
                agreement: 0.0,
                confidence: 0.50
            )
        }

        let agreementScore = Double(count) / Double(paths.count)
        let supportingPaths = answerPaths[consensusAnswer] ?? []
        let avgConfidence = supportingPaths.map(\.confidence).reduce(0, +) / Double(max(supportingPaths.count, 1))

        // Use the most detailed reasoning from supporting paths
        let bestReasoning = supportingPaths
            .max(by: { $0.reasoning.count < $1.reasoning.count })?
            .reasoning ?? ""

        return ConsensusResult(
            answer: consensusAnswer,
            supportingReasoning: bestReasoning,
            agreement: agreementScore,
            confidence: min(0.95, avgConfidence * agreementScore)
        )
    }
}
