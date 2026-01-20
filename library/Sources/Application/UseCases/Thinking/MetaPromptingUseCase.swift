import Foundation
import Domain

/// Meta-Prompting: Meta-instructions to guide prompting strategy
/// Single Responsibility: Execute meta-prompting
///
/// **Strategy:** Provide high-level instructions that guide the model to
/// adopt specific roles, perspectives, or reasoning strategies dynamically.
///
/// **Best for:**
/// - Complex, open-ended problems
/// - When domain expertise is needed
/// - Multi-perspective analysis
public struct MetaPromptingUseCase: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    public func execute(
        problem: String,
        context: String,
        metaInstructions: MetaInstructions
    ) async throws -> MetaPromptingResult {
        let prompt = buildMetaPrompt(
            problem: problem,
            context: context,
            meta: metaInstructions
        )

        let response = try await aiProvider.generateText(prompt: prompt, temperature: 0.7)

        return MetaPromptingResult(
            solution: response,
            problem: problem,
            roleAdopted: metaInstructions.role,
            perspectivesUsed: metaInstructions.perspectives,
            confidence: estimateConfidence(response, meta: metaInstructions)
        )
    }

    private func buildMetaPrompt(problem: String, context: String, meta: MetaInstructions) -> String {
        let metaSection = buildMetaSection(meta)
        return """
        \(metaSection)

        <context>
        \(context)
        </context>

        <problem>
        \(problem)
        </problem>

        <instructions>
        Apply the meta-instructions above to solve this problem.
        - Adopt the specified role and perspective
        - Use the recommended reasoning strategy
        - Meet the quality criteria
        - Be thorough and specific in your response
        </instructions>
        """
    }

    private func buildMetaSection(_ meta: MetaInstructions) -> String {
        var sections = ["<meta_instructions>"]
        if let role = meta.role {
            sections.append("You are a \(role.title) with expertise in \(role.domain).\nYour approach should reflect \(role.characteristics.joined(separator: ", ")).\n")
        }
        if let strategy = meta.reasoningStrategy {
            sections.append("Use the following reasoning approach:\n\(strategy)\n")
        }
        if !meta.perspectives.isEmpty {
            sections.append("Consider these perspectives:\n\(meta.perspectives.map { "- \($0)" }.joined(separator: "\n"))\n")
        }
        if !meta.qualityCriteria.isEmpty {
            sections.append("Ensure your response meets these quality criteria:\n\(meta.qualityCriteria.map { "- \($0)" }.joined(separator: "\n"))\n")
        }
        sections.append("</meta_instructions>")
        return sections.joined(separator: "\n")
    }

    private func estimateConfidence(_ response: String, meta: MetaInstructions) -> Double {
        var confidence = 0.70

        // Role adoption boosts confidence
        if meta.role != nil {
            confidence += 0.10
        }

        // Multiple perspectives indicate thorough analysis
        if meta.perspectives.count >= 2 {
            confidence += 0.10
        }

        // Explicit quality criteria improve reliability
        if meta.qualityCriteria.count >= 2 {
            confidence += 0.05
        }

        return min(0.95, confidence)
    }
}



