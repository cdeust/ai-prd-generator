import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Professional prompt template for generating Acceptance Criteria sections
///
/// Generates testable acceptance criteria including:
/// - Feature-level acceptance criteria
/// - Quality gates (what must pass before launch)
/// - Testing checklist (manual and automated)
/// - Success metrics (how to measure success post-launch)
public struct AcceptanceCriteriaPromptTemplate: SectionPromptStrategy {
    public var sectionType: SectionType { .acceptanceCriteria }

    public init() {}

    public func generatePrompt(for context: PromptContext) -> PromptTemplate {
        let systemPrompt = """
        You are a senior QA engineer and product manager with expertise in acceptance testing.
        You create clear, testable acceptance criteria that ensure quality and completeness.
        Your criteria are specific, measurable, and cover both functional and non-functional requirements.
        """

        let userPromptTemplate = """
        Define comprehensive acceptance criteria for this project:

        **Project:** {title}
        **Context:** {description}
        **Requirements:** {requirements}

        ## 1. FEATURE ACCEPTANCE CRITERIA

        For each major feature from the requirements, define testable acceptance criteria:

        **Feature: [Feature Name from Requirements]**

        Functional Criteria (checkbox format):
        - [ ] [Specific behavior - what must work]
        - [ ] [Edge case handling]
        - [ ] [Error scenario handling]

        Quality Criteria:
        - [ ] Performance: [Metric, e.g., "Responds within 200ms"]
        - [ ] Reliability: [Metric, e.g., "99.5% success rate"]

        ## 2. QUALITY GATES (What must pass before launch)

        **Code Quality:**
        - [ ] Unit tests pass with ≥80% coverage
        - [ ] No critical/high bugs remaining
        - [ ] Code reviewed and approved
        - [ ] Security scan clean

        **Performance** (if applicable):
        - [ ] Load test: Handles [X] concurrent users
        - [ ] API response: P95 < [X]ms
        - [ ] Recovery from peak load verified

        **Security** (if applicable):
        - [ ] Authentication/authorization tested
        - [ ] Data encryption verified
        - [ ] No exposed secrets

        **Usability** (if applicable):
        - [ ] UAT with [X] users completed
        - [ ] Accessibility audit passed
        - [ ] Cross-browser/device testing done

        **Documentation:**
        - [ ] API docs complete
        - [ ] User guide ready
        - [ ] Deployment runbook created

        ## 3. TESTING APPROACH

        **Manual Testing Scenarios:**
        List 4-6 key test scenarios with expected outcomes.

        **Automated Testing:**
        - Unit tests for [core logic]
        - Integration tests for [API/services]
        - E2E tests for [critical flows]

        ## 4. SUCCESS METRICS (Post-Launch)

        **Week 1:**
        - [Metric]: [Target] (e.g., "Error rate < 0.1%")
        - [Metric]: [Target] (e.g., "100+ active users")

        **Week 2-4:**
        - [Metric]: [Target] (e.g., "70% retention")
        - [Metric]: [Target] (e.g., "80% feature adoption")

        **Month 2-3:**
        - [Metric]: [Target] (e.g., "NPS > 50")

        **Guidelines:**
        - Every criterion must be TESTABLE - can you verify pass/fail?
        - Use specific numbers and metrics, not vague quality descriptions
        - Derive criteria from the requirements - test what you're building
        - Match rigor to project scope - MVP vs enterprise launch
        - Format as checkboxes for easy progress tracking
        - Cover functional correctness, performance, security, usability where relevant
        """

        let constraints = [
            "Define testable acceptance criteria for each major feature",
            "Include quality gates covering code, performance, security, usability, docs",
            "Every criterion must be verifiable as pass/fail with clear metrics",
            "Specify testing approach (manual scenarios + automated coverage)",
            "Define post-launch success metrics with specific targets",
            "Format as checkboxes for progress tracking",
            "Match rigor to project scope"
        ]

        let requirementsText = context.requirements.isEmpty
            ? "None specified - define acceptance criteria based on project description"
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
