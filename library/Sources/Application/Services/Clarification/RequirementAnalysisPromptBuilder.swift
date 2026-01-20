import Foundation
import Domain

/// Builds structured prompts for requirement gap analysis
///
/// Extracted for reusability and testability (3R's principle).
/// Constructs prompts with XML markup for clarity and consistency.
public struct RequirementAnalysisPromptBuilder {
    public init() {}

    /// Build complete analysis prompt from PRD request
    public func buildPrompt(from request: PRDRequest) -> String {
        let requestSection = buildPRDRequestSection(request)
        let frameworkSection = buildAnalysisFrameworkSection()
        let formatSection = buildOutputFormatSection()
        let guidelinesSection = buildGuidelinesSection()

        return """
        \(buildInstructionSection())

        \(requestSection)

        \(frameworkSection)

        \(formatSection)

        \(guidelinesSection)

        Generate 3-5 clarification questions, ordered by priority (highest first).
        """
    }

    private func buildInstructionSection() -> String {
        """
        <instruction>
        You are a PRODUCT MANAGER (not a developer) analyzing a PRD request for gaps.
        Your task:
        1. Identify missing HIGH-LEVEL PRODUCT information
        2. Generate 3-5 PRODUCT-LEVEL clarification questions
        3. Assess completeness (0-1 scale, where 1.0 = fully specified)
        4. Prioritize questions by business impact

        ONLY ask about: business goals, user workflows, scope boundaries, success metrics, business rules.
        NEVER ask about: database design, API details, validation rules, code patterns, technical implementation.
        </instruction>
        """
    }

    private func buildPRDRequestSection(_ request: PRDRequest) -> String {
        let requirementsText = formatRequirements(request.requirements)
        let constraintsText = formatConstraints(request.constraints)
        let platformText = formatPlatform(request.platform)
        let metadataText = formatMetadata(request.metadata)

        return """
        <prd-request>
        <title>\(request.title)</title>
        <description>\(request.description)</description>
        <requirements>
        \(requirementsText)
        </requirements>
        <constraints>
        \(constraintsText)
        </constraints>
        <platform>\(platformText)</platform>
        \(metadataText)
        </prd-request>
        """
    }

    private func formatRequirements(_ requirements: [Requirement]) -> String {
        requirements.isEmpty
            ? "No requirements specified."
            : requirements.map { $0.description }.joined(separator: "\n")
    }

    private func formatConstraints(_ constraints: [String]) -> String {
        constraints.isEmpty
            ? "No constraints specified."
            : constraints.joined(separator: "\n")
    }

    private func formatPlatform(_ platform: Platform?) -> String {
        platform.map { "Platform: \($0.rawValue)" } ?? "Platform not specified."
    }

    private func formatMetadata(_ metadata: [String: String]) -> String {
        guard !metadata.isEmpty else { return "" }

        let items = metadata.map { "<\($0.key)>\($0.value)</\($0.key)>" }
        return """
        <metadata>
        \(items.joined(separator: "\n"))
        </metadata>
        """
    }

    private func buildAnalysisFrameworkSection() -> String {
        """
        <analysis-framework>
        Evaluate across PRODUCT dimensions only (NOT technical implementation):

        1. BUSINESS VALUE: What problem is solved? Who benefits? What's the ROI?
        2. USER EXPERIENCE: Target audience, user journeys, workflows, pain points
        3. SCOPE: What's explicitly in/out? What are the boundaries?
        4. SUCCESS METRICS: How will success be measured? What are the KPIs?
        5. BUSINESS RULES: What policies, constraints, or logic govern behavior?

        DO NOT evaluate: database design, API structure, code architecture, validation rules, error handling.
        </analysis-framework>
        """
    }

    private func buildOutputFormatSection() -> String {
        """
        <output-format>
        IMPORTANT: You MUST output questions in this EXACT format:

        COMPLETENESS_SCORE: [0.0-1.0]
        CONFIDENCE: [0.0-1.0]

        QUESTION_1:
        CATEGORY: [technical|business|user|scope|risk]
        PRIORITY: [1-100, where 100 = critical, 1 = low]
        GAP_TYPE: [brief identifier]
        QUESTION: [specific, actionable question]
        RATIONALE: [why this matters for PRD quality]
        EXAMPLES: [2-3 example answers, pipe-separated]

        QUESTION_2:
        CATEGORY: [category]
        PRIORITY: [priority number]
        GAP_TYPE: [gap identifier]
        QUESTION: [question text]
        RATIONALE: [rationale text]
        EXAMPLES: [example1 | example2 | example3]

        ... (continue for 3-5 questions)
        </output-format>
        """
    }

    private func buildGuidelinesSection() -> String {
        """
        <guidelines>
        - Ask HIGH-LEVEL PRODUCT questions only
        - Questions should be answerable by a product owner, not a developer
        - Prioritize by business impact
        - Focus on WHAT to build, not HOW to build it
        - NEVER ask about: mandatory fields, validation rules, database columns, API endpoints
        </guidelines>

        <example-output>
        Example response for a "user favorites" feature:

        COMPLETENESS_SCORE: 0.4
        CONFIDENCE: 0.85

        QUESTION_1:
        CATEGORY: business
        PRIORITY: 95
        GAP_TYPE: user_workflow
        QUESTION: What can users add to favorites - only products, or also categories, searches, and stores?
        RATIONALE: Defines the scope of what the favorites feature covers
        EXAMPLES: Products only | Products and categories | Products, categories, and saved searches

        QUESTION_2:
        CATEGORY: scope
        PRIORITY: 90
        GAP_TYPE: feature_boundary
        QUESTION: Should favorites sync across devices, or stay local to each device?
        RATIONALE: Cross-device sync significantly changes the feature scope and user expectations
        EXAMPLES: Local only | Synced for logged-in users | Always synced with guest migration
        </example-output>
        """
    }
}
