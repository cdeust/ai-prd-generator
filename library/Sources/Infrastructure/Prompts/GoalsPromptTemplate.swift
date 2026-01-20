import Foundation
import Domain

/// Professional prompt template for generating Goals sections
///
/// Generates SMART (Specific, Measurable, Achievable, Relevant, Time-bound) goals
/// across multiple categories:
/// - Business Goals (revenue, market share, growth)
/// - User Goals (satisfaction, engagement, retention)
/// - Technical Goals (performance, scalability, reliability)
/// - Timeline Goals (milestones, deadlines)
public struct GoalsPromptTemplate: SectionPromptStrategy {
    public var sectionType: SectionType { .goals }

    public init() {}

    public func generatePrompt(for context: PromptContext) -> PromptTemplate {
        let systemPrompt = """
        You are a senior product manager specializing in goal setting and OKR (Objectives and Key Results) frameworks.
        You create SMART goals that are ambitious yet achievable, with clear success metrics.
        Your goals are always specific, measurable, and tied to business outcomes.
        """

        let userPromptTemplate = """
        Define clear, measurable goals for this project:

        **Project:** {title}
        **Context:** {description}
        **Requirements:** {requirements}

        Create 4-7 SMART goals that cover different dimensions:

        **What makes a good goal:**
        - Specific enough to know exactly what success looks like
        - Measurable with concrete numbers, not vague improvements
        - Time-bound with realistic deadlines based on project scope
        - Includes clear success criteria for verification

        **Goal Types to Consider:**

        **Business Impact:**
        What quantifiable business outcome should this achieve? Think revenue, cost savings, market position, user growth. If it's an internal tool, consider productivity gains or error reductions.

        **User Experience:**
        What measurable improvement in user satisfaction or engagement should occur? Think retention rates, satisfaction scores, task completion times, or adoption rates.

        **Technical Performance:**
        What specific technical metrics must the system meet? Think response times (P50, P95, P99), throughput (requests/second), uptime percentage, or resource efficiency.

        **Delivery Milestones:**
        What are the key deliverables and when? Be specific about what "done" means for each milestone, not just dates.

        **Format Guidelines:**
        For each goal, write it naturally but include:
        - The goal statement (what you're trying to achieve)
        - The metric/target (specific number, percentage, or outcome)
        - Success criteria in parentheses: (Success: how to verify)
        - Timeline if applicable

        **Example (good):**
        "Execute automated trades with sub-second latency to capitalize on market opportunities. Target: 95th percentile trade execution under 500ms. (Success: Load testing shows P95 < 500ms under peak trading volume)"

        **Example (bad - too vague):**
        "Improve system performance" - No metric, no timeline, not measurable

        **Guidelines:**
        - Extract goals from the project description and requirements - don't invent goals not implied by the project
        - Be realistic about timelines based on project scope (a "7-day bot" shouldn't have "6-month goals")
        - Use actual numbers from the description when provided
        - Make goals challenging but achievable
        - Every goal must answer "How will we know we succeeded?"
        """

        let constraints = [
            "Create 4-7 goals covering business, user experience, technical, and delivery dimensions",
            "Every goal must be SMART with specific metrics and numbers",
            "Include success criteria showing how to verify achievement",
            "Derive goals from project context - don't invent unrelated goals",
            "Match timeline realism to project scope",
            "Avoid vague aspirations without measurable targets"
        ]

        let requirementsText = context.requirements.isEmpty
            ? "None specified - infer reasonable goals from title and description"
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
