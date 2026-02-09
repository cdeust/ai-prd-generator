import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

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
        - **MUST include baseline value with source** for comparison

        **Goal Types to Consider:**

        **Business Impact:**
        What quantifiable business outcome should this achieve? Think revenue, cost savings, market position, user growth. If it's an internal tool, consider productivity gains or error reductions.

        **User Experience:**
        What measurable improvement in user satisfaction or engagement should occur? Think retention rates, satisfaction scores, task completion times, or adoption rates.

        **Technical Performance:**
        What specific technical metrics must the system meet? Think response times (P50, P95, P99), throughput (requests/second), uptime percentage, or resource efficiency.

        **Delivery Milestones:**
        What are the key deliverables and when? Be specific about what "done" means for each milestone, not just dates.

        ## CRITICAL: BASELINE REQUIREMENTS ##

        **Every measurable goal MUST include:**
        1. **Current baseline** (what is the current state?)
        2. **Target value** (what should it become?)
        3. **Source** for the baseline (where did this number come from?)

        **EXTRACT BASELINES FROM AVAILABLE CONTEXT (priority order):**

        1. **From Codebase** (HIGHEST PRIORITY - look for these patterns):
           - Monitoring/metrics code (Prometheus, DataDog, NewRelic integrations)
           - Test assertions with performance thresholds (`expect(latency).toBeLessThan(200)`)
           - SLA/config files with defined thresholds
           - Analytics event tracking code
           - Logging patterns showing current behavior
           - README/docs mentioning current performance
           - Error rate calculations in existing code

        2. **From Mockups** (if provided):
           - Current state screens showing existing metrics
           - Dashboard mockups with visible KPIs
           - Before/after comparisons in the design

        3. **From Requirements** (if mentioned):
           - User-provided current metrics in the description
           - Referenced existing system performance

        4. **Sector-specific inference** (ONLY if not in context):
           - Derive from the product type and sector
           - Must specify the sector assumption

        5. **TBD with extraction method** (LAST RESORT):
           - "Baseline: TBD — *Extract from [specific code path/metric name] before launch*"

        **DO NOT:**
        - Use generic industry averages without sector context
        - Ask the user for baselines that exist in the codebase
        - Guess without citing source

        **Example - extracting from codebase:**
        "Reduce checkout abandonment rate.
        - **Baseline:** 68% — *Source: Extracted from analytics/checkoutMetrics.ts line 45*
        - **Target:** < 40%"

        **Format Guidelines:**
        For each goal, use this format:
        - The goal statement (what you're trying to achieve)
        - **Baseline:** [current value] — *Source: [citation]*
        - **Target:** [target value]
        - **Success Criteria:** (how to verify)
        - Timeline if applicable

        **Example (good):**
        "Reduce API response latency to improve user experience.
        - **Baseline:** 450ms P95 — *Source: Current APM metrics (Jan 2024)*
        - **Target:** < 200ms P95
        - **Success Criteria:** New Relic shows P95 < 200ms for 7 consecutive days"

        **Example (bad - no baseline):**
        "Improve API response latency to under 200ms" — Missing baseline and source

        **Guidelines:**
        - Extract goals from the project description and requirements - don't invent goals not implied by the project
        - Be realistic about timelines based on project scope (a "7-day bot" shouldn't have "6-month goals")
        - Use actual numbers from the description when provided
        - If baseline is unknown, state "Baseline: TBD — *Source: Requires measurement before launch*"
        - NEVER use "N/A" as a baseline - always provide a value or mark as TBD with measurement plan
        - Every goal must answer "How will we know we succeeded?"
        """

        let constraints = [
            "Create 4-7 goals covering business, user experience, technical, and delivery dimensions",
            "Every goal must be SMART with specific metrics and numbers",
            "MANDATORY: Every measurable goal must include baseline value with source citation",
            "Include success criteria showing how to verify achievement",
            "Derive goals from project context - don't invent unrelated goals",
            "Match timeline realism to project scope",
            "Avoid vague aspirations without measurable targets",
            "NEVER use 'N/A' as baseline - use 'TBD' with measurement plan if unknown",
            "Cite baseline sources: internal data, industry reports, or mark as [estimated]"
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
