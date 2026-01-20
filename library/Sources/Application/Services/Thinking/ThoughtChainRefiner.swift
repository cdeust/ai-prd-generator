import Foundation
import Domain

/// Refines ThoughtChain results with feedback-driven re-reasoning
///
/// **3R's Justification:**
/// - **Reliability**: Testable refinement logic in isolation
/// - **Readability**: Clear separation of refinement concerns
/// - **Reusability**: Any CoT variant can use this
///
/// Single Responsibility: Refine thought chains based on quality feedback
public struct ThoughtChainRefiner: Sendable {
    private let aiProvider: AIProviderPort
    private let responseParser: StructuredCoTParser

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
        self.responseParser = StructuredCoTParser()
    }

    /// Refine ThoughtChain by re-reasoning with feedback
    public func refine(
        previousChain: ThoughtChain,
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> ThoughtChain {
        let feedback = extractReasoningFeedback(previousChain)

        let prompt = buildRefinementPrompt(
            problem: problem,
            context: context,
            constraints: constraints,
            previousChain: previousChain,
            feedback: feedback
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.7
        )

        let parsed = responseParser.parse(response)

        return ThoughtChain(
            id: UUID(),
            problem: problem,
            thoughts: parsed.thoughts,
            conclusion: parsed.conclusion,
            confidence: parsed.confidence,
            alternatives: previousChain.alternatives,
            assumptions: parsed.assumptions,
            timestamp: Date()
        )
    }

    // MARK: - Private Methods

    private func extractReasoningFeedback(_ chain: ThoughtChain) -> String {
        var feedback = ""

        if chain.confidence < 0.7 {
            feedback += "Low confidence (\(String(format: "%.2f", chain.confidence))). "
            feedback += "Strengthen reasoning with more evidence.\n\n"
        }

        if chain.assumptions.count > 5 {
            feedback += "Many assumptions (\(chain.assumptions.count)). "
            feedback += "Validate or eliminate weak assumptions.\n\n"
        }

        if chain.thoughts.count < 3 {
            feedback += "Shallow reasoning (\(chain.thoughts.count) thoughts). "
            feedback += "Explore problem more deeply.\n\n"
        }

        return feedback.isEmpty ? "Good reasoning. Refine further." : feedback
    }

    private func buildRefinementPrompt(
        problem: String,
        context: String,
        constraints: [String],
        previousChain: ThoughtChain,
        feedback: String
    ) -> String {
        """
        Refine your reasoning for this problem based on feedback:

        <problem>
        \(problem)
        </problem>

        <context>
        \(context)
        </context>

        <constraints>
        \(constraints.map { "- \($0)" }.joined(separator: "\n"))
        </constraints>

        <previous_reasoning>
        Conclusion: \(previousChain.conclusion)
        Confidence: \(String(format: "%.2f", previousChain.confidence))

        Thoughts:
        \(previousChain.thoughts.enumerated().map { "\($0.offset + 1). \($0.element.content)" }
            .joined(separator: "\n"))

        Assumptions:
        \(previousChain.assumptions.map { "- \($0.description)" }.joined(separator: "\n"))
        </previous_reasoning>

        <feedback>
        \(feedback)
        </feedback>

        Provide improved structured reasoning:
        - Address the feedback
        - Strengthen weak points
        - Validate assumptions
        - Increase confidence through better evidence
        """
    }
}
