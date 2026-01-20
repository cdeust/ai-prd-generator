import Foundation
import Domain

/// Generate Knowledge Prompting: Generate relevant knowledge first, then solve
/// Single Responsibility: Execute knowledge-generation-then-reasoning
///
/// **Strategy:** First ask model to generate relevant domain knowledge,
/// then use that knowledge to solve the problem. Two-stage process.
///
/// **Best for:**
/// - Knowledge-intensive tasks
/// - Domain-specific problems
/// - When problem requires background context
public struct GenerateKnowledgeUseCase: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    public func execute(
        problem: String,
        context: String,
        domain: String
    ) async throws -> GenerateKnowledgeResult {
        // Stage 1: Generate relevant knowledge
        let knowledgePrompt = buildKnowledgeGenerationPrompt(
            problem: problem,
            context: context,
            domain: domain
        )

        let generatedKnowledge = try await aiProvider.generateText(prompt: knowledgePrompt, temperature: 0.5)

        // Stage 2: Solve problem using generated knowledge
        let solutionPrompt = buildSolutionPrompt(
            problem: problem,
            context: context,
            knowledge: generatedKnowledge
        )

        let solution = try await aiProvider.generateText(prompt: solutionPrompt, temperature: 0.7)

        return GenerateKnowledgeResult(
            solution: solution,
            generatedKnowledge: generatedKnowledge,
            problem: problem,
            confidence: estimateConfidence(solution, knowledge: generatedKnowledge)
        )
    }

    private func buildKnowledgeGenerationPrompt(
        problem: String,
        context: String,
        domain: String
    ) -> String {
        """
        <task>
        Generate relevant domain knowledge that would help solve the following problem.
        </task>

        <domain>
        \(domain)
        </domain>

        <context>
        \(context)
        </context>

        <problem>
        \(problem)
        </problem>

        <instructions>
        Before solving this problem, generate relevant knowledge about:
        1. Key concepts and definitions in this domain
        2. Common patterns or best practices
        3. Important considerations or constraints
        4. Relevant technical details or specifications

        Focus on knowledge that would directly help solve this specific problem.
        Be concise but comprehensive.
        </instructions>
        """
    }

    private func buildSolutionPrompt(
        problem: String,
        context: String,
        knowledge: String
    ) -> String {
        """
        <generated_knowledge>
        Here is relevant domain knowledge for this problem:

        \(knowledge)
        </generated_knowledge>

        <context>
        \(context)
        </context>

        <problem>
        \(problem)
        </problem>

        <instructions>
        Using the domain knowledge provided above, solve this problem:
        1. Apply the relevant concepts and best practices
        2. Consider the constraints and technical details
        3. Provide a well-reasoned solution
        4. Explain how the generated knowledge informed your answer

        Be specific and actionable in your solution.
        </instructions>
        """
    }

    private func estimateConfidence(_ solution: String, knowledge: String) -> Double {
        // Confidence based on how well knowledge was utilized
        let solutionLower = solution.lowercased()
        let knowledgeLower = knowledge.lowercased()

        // Extract key phrases from knowledge (simplified)
        let knowledgeWords = Set(knowledgeLower.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 5 })

        let solutionWords = Set(solutionLower.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 5 })

        // Calculate overlap
        let overlap = knowledgeWords.intersection(solutionWords)
        let utilizationRate = Double(overlap.count) / Double(max(knowledgeWords.count, 1))

        // Higher utilization → higher confidence
        if utilizationRate > 0.3 {
            return 0.85  // Good knowledge utilization
        } else if utilizationRate > 0.15 {
            return 0.75  // Moderate utilization
        } else {
            return 0.65  // Low utilization, knowledge may not have helped
        }
    }
}
