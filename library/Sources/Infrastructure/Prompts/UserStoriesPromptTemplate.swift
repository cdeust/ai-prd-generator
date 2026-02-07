import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Professional prompt template for generating User Stories sections
///
/// Generates comprehensive user stories including:
/// - User personas (who are the users?)
/// - User journeys (what are they trying to achieve?)
/// - Story format (As a [user], I want [goal], so that [benefit])
/// - Edge cases and scenarios
public struct UserStoriesPromptTemplate: SectionPromptStrategy {
    public var sectionType: SectionType { .userStories }

    public init() {}

    public func generatePrompt(for context: PromptContext) -> PromptTemplate {
        let systemPrompt = """
        You are a senior product manager and UX researcher with expertise in user-centered design.
        You create detailed user personas and user stories that capture real user needs.
        Your stories follow the standard format and include context about user motivations.
        """

        let userPromptTemplate = """
        Create user-centered stories for this project:

        **Project:** {title}
        **Context:** {description}
        **Requirements:** {requirements}

        ## USER PERSONAS (2-3 personas)

        Create realistic personas based on who would actually use this product. Give them names and make them specific:

        **[Name/Role]** (e.g., "Marcus, the Day Trader" or "Sofia, Backend Engineer")
        - What they do and their context
        - Their primary goals with this product
        - Their pain points or frustrations
        - Their technical comfort level
        - When/where/how they'd use it

        Make these realistic - not generic "the user" or "average person". Who ACTUALLY uses products like this?

        ## USER JOURNEYS (for each persona)

        Briefly describe their typical journey:
        1. How they discover/start using the product
        2. Their first-time experience
        3. Their regular usage pattern
        4. Advanced needs (if applicable)

        ## USER STORIES (8-12 stories)

        Write stories in this format:
        **US-[number]: [Descriptive Title]**
        As a [specific persona/role],
        I want [specific capability],
        So that [real benefit/outcome].

        **Acceptance Criteria:**
        - Given [starting condition]
        - When [user action]
        - Then [expected result]

        **Priority:** Critical/High/Medium/Low

        **Cover these story types:**
        - Core workflows (must-have functionality)
        - Optimization/convenience (making tasks easier)
        - Error handling (when things go wrong)
        - Edge cases (unusual but important scenarios)

        **Example:**
        ```
        US-1: Execute Rapid Market Order
        As Marcus the day trader,
        I want to execute buy orders with one click,
        So that I can capitalize on price movements within seconds.

        Acceptance Criteria:
        - Given I'm logged in and viewing a crypto pair
        - When I click "Quick Buy $100"
        - Then order executes within 2 seconds with visual confirmation

        Priority: Critical
        ```

        ## IMPORTANT EDGE CASES (3-5 scenarios)

        What unusual but important scenarios must the system handle?
        - What if [error/failure condition]?
        - How does it handle [unexpected input]?
        - What happens when [resource limit/constraint]?

        **Guidelines:**
        - Ground personas in the actual target users for THIS project
        - Make stories specific to the project requirements - don't add unrelated features
        - Every story needs testable acceptance criteria (Given/When/Then)
        - Priority should reflect actual importance - not everything is Critical
        - Focus on USER VALUE - what can users accomplish, not how it's built
        - Derive stories from requirements - don't invent features not in scope
        """

        let constraints = [
            "Create 2-3 realistic, named personas grounded in actual target users",
            "Use 'As a... I want... So that...' format for all stories",
            "Include Given/When/Then acceptance criteria for every story",
            "Prioritize stories realistically (not everything is Critical)",
            "Cover core workflows, optimizations, error handling, and edge cases",
            "Derive all stories from project requirements and context",
            "Focus on user value, not technical implementation"
        ]

        let requirementsText = context.requirements.isEmpty
            ? "None specified - infer user stories from project description"
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
