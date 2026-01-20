import Foundation
import Domain

/// Helper for injecting enriched context into prompts
///
/// Handles XML-formatted injection of section context and intelligence context
/// (RAG + Reasoning) into PRD generation prompts.
///
/// **Budget-Aware:** Works with pre-selected context from BudgetAwareContextSelector
/// to ensure prompts stay within model context window limits.
struct EnrichedContextInjector: Sendable {
    /// Inject section-specific enriched context into a professional prompt
    /// - Parameters:
    ///   - prompt: Base prompt (instructions + template)
    ///   - sectionContext: Section-specific context
    ///   - enrichedContext: Section-specific enriched intelligence (pre-selected, not truncated)
    /// - Returns: Complete prompt with context injected
    func injectContext(
        into prompt: String,
        sectionContext: SectionContext,
        enrichedContext: String
    ) -> String {
        var result = prompt

        // Add section-specific context
        if !sectionContext.relevantContext.isEmpty {
            result += """

            <section_context>
            \(sectionContext.relevantContext)
            </section_context>
            """
        }

        // Add section-specific enriched intelligence (RAG + Reasoning)
        if !enrichedContext.isEmpty {
            result += """

            <intelligence_context>
            \(enrichedContext)

            Use this intelligence to make the PRD more context-aware and aligned with existing patterns.
            </intelligence_context>
            """
        }

        return result
    }

    /// Build fallback section prompt with section-specific enriched context
    func buildFallbackPrompt(
        sectionType: SectionType,
        sectionContext: SectionContext,
        enrichedContext: String
    ) -> String {
        var prompt = """
        <instruction>
        You are a senior product manager writing a Product Requirements Document.
        Generate the \(sectionType.displayName) section.
        </instruction>

        <input>
        Title: \(sectionContext.title)
        Description: \(sectionContext.description)
        </input>
        """

        // Add section-specific context
        if !sectionContext.relevantContext.isEmpty {
            prompt += """

            <section_context>
            \(sectionContext.relevantContext)
            </section_context>
            """
        }

        // Add section-specific enriched intelligence
        if !enrichedContext.isEmpty {
            prompt += """

            <intelligence_context>
            \(enrichedContext)
            </intelligence_context>
            """
        }

        prompt += """

        <requirements>
        - Follow professional PRD standards
        - Be specific and concrete
        - Avoid generic statements
        - Use insights from intelligence context to inform your response
        </requirements>
        """

        return prompt
    }
}
