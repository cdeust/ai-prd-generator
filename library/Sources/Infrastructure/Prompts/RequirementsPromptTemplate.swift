import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Professional prompt template for generating Requirements sections
///
/// Generates detailed requirements with priorities across:
/// - Functional Requirements (what the system must do)
/// - Non-Functional Requirements (performance, security, scalability)
/// Each requirement includes priority, rationale, and acceptance criteria.
public struct RequirementsPromptTemplate: SectionPromptStrategy {
    public var sectionType: SectionType { .requirements }

    public init() {}

    public func generatePrompt(for context: PromptContext) -> PromptTemplate {
        let systemPrompt = """
        You are a senior product manager and business analyst with expertise in requirements engineering.
        You write precise, testable requirements following IEEE 830 standards.
        Your requirements are always verifiable, unambiguous, and prioritized.
        """

        let userPromptTemplate = """
        Define comprehensive requirements for this project:

        **Project:** {title}
        **Context:** {description}
        **User Requirements:** {requirements}

        Break requirements into functional (what the system does) and non-functional (how well it does it).

        ## FUNCTIONAL REQUIREMENTS

        List what the system must DO. Organize by priority:
        - **Critical**: System cannot function without this
        - **High**: Necessary for full value
        - **Medium**: Valuable but can be deferred
        - **Low**: Nice to have for future versions

        For each functional requirement, provide:
        - **FR-[number]**: Brief name
        - **Priority**: Critical/High/Medium/Low
        - **Description**: What the system must do (1-2 sentences, specific)
        - **Rationale**: Why this matters to users or business
        - **Acceptance Criteria**: How to verify it works (testable conditions)

        Extract these from the project description and user requirements. Don't invent features not implied by the project scope.

        ## NON-FUNCTIONAL REQUIREMENTS

        Define quality attributes with SPECIFIC metrics:

        **Performance** (if relevant):
        What response times, throughput, or resource limits apply? Use actual numbers: "API responds within 200ms for 95% of requests" not "fast API responses".

        **Security** (if relevant):
        What authentication, authorization, or data protection is needed? Be specific: "Support OAuth 2.0 with JWT tokens" not "secure authentication".

        **Scalability** (if relevant):
        How many concurrent users, data volume, or growth capacity? "Support 10,000 concurrent users" not "highly scalable".

        **Reliability** (if relevant):
        What uptime, error rates, or recovery times? "99.5% uptime SLA, auto-recovery within 5 minutes" not "reliable system".

        **Usability** (if relevant):
        What accessibility, browser support, or UX standards? "WCAG 2.1 AA compliant" not "accessible to all users".

        **Compliance** (if relevant):
        What regulations or standards must be met? "GDPR compliant data handling" not "follows best practices".

        For each non-functional requirement:
        - **NFR-[number]**: Category and name
        - **Metric/Constraint**: Specific, measurable target
        - **Rationale**: Why this level matters
        - **Verification**: How to measure or test

        **Guidelines:**
        - EVERY requirement must be verifiable - can you test whether it's met?
        - Use numbers, percentages, and time limits - never vague terms without metrics
        - Derive requirements from project context - match complexity to project scope
        - If it's a simple/small project, don't add enterprise-scale requirements
        - If it's a prototype/MVP, focus on core Critical/High requirements
        - Prioritize honestly - not everything can be Critical
        """

        let constraints = [
            "Include both Functional and Non-Functional requirements",
            "Prioritize functional requirements realistically (Critical/High/Medium/Low)",
            "Every requirement must be testable and verifiable",
            "Use specific metrics and numbers for non-functional requirements",
            "Derive all requirements from project context - don't invent unrelated features",
            "Match requirement complexity to project scope",
            "Use requirement IDs (FR-1, NFR-1, etc.)"
        ]

        let requirementsText = context.requirements.isEmpty
            ? "None specified - infer requirements from title and description"
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
