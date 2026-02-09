import AIPRDSharedUtilities
import Foundation

/// Professional prompt template for generating Overview sections
///
/// Generates comprehensive overviews that include:
/// - Problem statement (what problem does this solve?)
/// - Solution summary (high-level approach)
/// - Target audience (who is this for?)
/// - Key value propositions (why this matters)
/// - Scope boundaries (what's in/out of scope)
public struct OverviewPromptTemplate: SectionPromptStrategy {
    public var sectionType: SectionType { .overview }

    public init() {}

    public func generatePrompt(for context: PromptContext) -> PromptTemplate {
        let systemPrompt = """
        You are a senior product manager with 10+ years of experience writing Product Requirements Documents.
        Your expertise is in clearly articulating problems, solutions, and value propositions.
        You write in a clear, professional tone with specific, actionable statements.
        """

        let userPromptTemplate = """
        Write a compelling PRD Overview section for this project:

        **Project:** {title}
        **Context:** {description}
        **Requirements:** {requirements}

        Your Overview should naturally address:

        **The Problem Context:**
        What specific pain point exists today? Who experiences it? What are the consequences of not solving it? Ground this in the project description - extract the real problem, don't invent generic ones.

        **The Proposed Solution:**
        Describe the solution approach in 2-3 sentences. Focus on HOW it works and WHY this approach makes sense. Be specific about the mechanism, not just "we will build a system."

        **Who It's For:**
        Describe the target users concretely. Instead of "users who want X," describe actual personas briefly: their role, context, and what they're trying to accomplish. Use the requirements to infer this.

        **Why It Matters:**
        State 3-4 concrete benefits or outcomes. Make these specific to THIS project - avoid generic claims like "improves efficiency" without quantifying how or for whom.

        **Scope Clarity:**
        Clearly state what IS included in this first version and what explicitly will NOT be built. Use the requirements to infer boundaries.

        **Guidelines:**
        - Extract specific details from the title, description, and requirements - don't add generic filler
        - Write naturally, not as a bulleted checklist
        - Be concrete and specific - use numbers, timeframes, and specific technologies when evident
        - Avoid meta-statements like "This document describes..." - jump straight into the content
        - If the description mentions specific constraints (time, budget, technology), incorporate them
        - Length target: 250-400 words, but prioritize substance over hitting exact word count
        """

        let constraints = [
            "Ground all content in the provided title, description, and requirements",
            "Be specific and concrete - use actual details, not generic placeholders",
            "Cover problem context, solution approach, target users, benefits, and scope",
            "Avoid meta-statements about the document itself",
            "State scope boundaries clearly (what's included vs excluded)",
            "Write naturally as prose, not as a checklist or template"
        ]

        let requirementsText = context.requirements.isEmpty
            ? "None specified"
            : context.requirements.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")

        return PromptTemplate(
            systemPrompt: systemPrompt,
            userPromptTemplate: userPromptTemplate,
            variables: [
                "title": context.title,
                "description": context.description,
                "requirements": requirementsText
            ],
            constraints: constraints
        )
    }
}
