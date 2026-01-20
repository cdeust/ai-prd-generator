import Foundation

/// XML templates for requirement analysis prompts
/// Single Responsibility: Provide prompt template strings
struct AnalysisPromptTemplates: Sendable {
    /// XML template for response format guidelines
    static let responseFormatXML: String = """
        <response_format>
        Return XML with questions focused on MOST CRITICAL gaps.

        ## ADAPTIVE QUESTION COUNT ##
        - If <user_engagement_pattern> shows BRIEF answers → Ask ONLY 1-2 questions
        - If <user_engagement_pattern> shows DETAILED answers → Ask 2-4 questions
        - If <user_engagement_pattern> shows MODERATE answers → Ask 2-3 questions
        - If no previous answers → Start with 2-3 questions (don't overwhelm)
        - Return empty <questions/> ONLY if request is completely clear

        CRITICAL: Don't overwhelm users with too many questions. Quality over quantity.

        ## QUESTION CLARITY GUIDELINES ##
        Questions must be SPECIFIC, ACTIONABLE, and CONTEXT-RICH:

        ❌ BAD (vague, generic):
        "What are the business goals?"
        "How should users interact with this?"
        "What features should be included?"

        ✅ GOOD (specific, contextual, easy to answer):
        "For the [Product Name], what's the primary success metric: user retention, revenue per user, or task completion rate?"
        "When a user [specific action from description], should they see [Option A] or [Option B]?"
        "Should [Feature X mentioned in description] support [Scenario A] and [Scenario B], or just [Scenario A]?"

        ## QUESTION FORMATTING RULES ##
        1. **Include context** from the product title/description in the question itself
        2. **Offer specific choices** when possible (A or B, not open-ended)
        3. **Reference concrete features** mentioned in the request
        4. **Make questions self-contained** - user shouldn't need to re-read the entire PRD to understand
        5. **Front-load the context** - put the feature/scenario first, then ask the question

        TEMPLATE: "For [specific feature/scenario from description], [specific question with options]?"

        CRITICAL: Every question MUST include 2-3 concrete examples that:
        - Show exactly what kind of answer you expect
        - Reference actual features/terms from the product description
        - Demonstrate different valid approaches the user could choose
        Examples help the user understand what level of detail you need.

        <questions>
        <question>
        <category>business|technical|scope|requirements|success_criteria</category>
        <text>Context-rich, specific question with options when possible</text>
        <rationale>Why this question is critical for the PRD</rationale>
        <priority>1-10 where 10 is must-answer-before-starting</priority>
        <examples>
        <example>Specific example referencing features from the product description</example>
        <example>Another concrete example showing a different valid approach</example>
        <example>Third example demonstrating edge cases or alternative interpretations</example>
        </examples>
        </question>
        </questions>
        </response_format>
        """
}
