import Foundation
import Domain

/// Builds prompts for requirement analysis
/// Single Responsibility: Construct analysis prompts for LLM
struct AnalysisPromptBuilder: Sendable {
    private let engagementAnalyzer = UserEngagementAnalyzer()
    private let pruner = ClarificationPruner()

    func buildCodebaseAwarePrompt(
        request: PRDRequest,
        codebaseContext: RAGSearchResults,
        mockupSummaries: [String] = [],
        previousClarifications: [(question: String, answer: String)] = [],
        contextWindowSize: Int
    ) -> String {
        let codeSnippets = codebaseContext.relevantChunks.prefix(5).joined(separator: "\n---\n")
        let fileList = codebaseContext.relevantFiles.prefix(10).joined(separator: ", ")
        let taskXML = buildTaskXML(
            hasMockups: !mockupSummaries.isEmpty,
            hasPreviousClarifications: !previousClarifications.isEmpty,
            includeCodebaseWarning: true
        )

        // Build base prompt without clarifications
        let basePrompt = """
        <system>
        You are a senior software architect analyzing a PRD request to identify gaps.
        </system>

        \(buildRequestXML(request))

        <codebase_context>
        <relevant_files>\(fileList)</relevant_files>
        <code_snippets>
        \(codeSnippets)
        </code_snippets>
        </codebase_context>

        \(buildMockupContextXML(mockupSummaries))
        """

        // Prune clarifications if needed to fit context window
        let prunedClarifications = pruner.pruneClarificationsToFit(
            basePrompt: basePrompt + "\n\n\(taskXML)\n\n\(AnalysisPromptTemplates.responseFormatXML)",
            clarifications: previousClarifications,
            contextWindowSize: contextWindowSize
        )

        return """
        \(basePrompt)

        \(buildClarificationsXML(prunedClarifications))

        \(taskXML)

        \(AnalysisPromptTemplates.responseFormatXML)
        """
    }

    func buildStandalonePrompt(
        request: PRDRequest,
        mockupSummaries: [String] = [],
        previousClarifications: [(question: String, answer: String)] = [],
        contextWindowSize: Int
    ) -> String {
        let metadataXML = request.metadata.map { "<\($0.key)>\($0.value)</\($0.key)>" }.joined(separator: "\n")
        let taskXML = buildTaskXML(
            hasMockups: !mockupSummaries.isEmpty,
            hasPreviousClarifications: !previousClarifications.isEmpty,
            includeCodebaseWarning: false
        )

        // Build base prompt without clarifications
        let basePrompt = """
        <system>
        You are a senior software architect analyzing a PRD request to identify gaps.
        </system>

        \(buildRequestXML(request))
        <metadata>
        \(metadataXML.isEmpty ? "<none/>" : metadataXML)
        </metadata>

        \(buildMockupContextXML(mockupSummaries))
        """

        // Prune clarifications if needed to fit context window
        let prunedClarifications = pruner.pruneClarificationsToFit(
            basePrompt: basePrompt + "\n\n\(taskXML)\n\n\(AnalysisPromptTemplates.responseFormatXML)",
            clarifications: previousClarifications,
            contextWindowSize: contextWindowSize
        )

        return """
        \(basePrompt)

        \(buildClarificationsXML(prunedClarifications))

        \(taskXML)

        \(AnalysisPromptTemplates.responseFormatXML)
        """
    }

    private func buildMockupContextXML(_ summaries: [String]) -> String {
        guard !summaries.isEmpty else { return "" }
        let mockupsXML = summaries.enumerated().map { index, summary in
            "<mockup index=\"\(index + 1)\">\(summary)</mockup>"
        }.joined(separator: "\n")
        return """
        <mockup_analysis>
        The following UI mockups were provided and analyzed:
        \(mockupsXML)
        Use these mockup details to generate context-specific examples in your questions.
        </mockup_analysis>
        """
    }

    /// Build XML showing Q&A pairs already clarified - LLM sees both question AND answer
    private func buildClarificationsXML(_ clarifications: [(question: String, answer: String)]) -> String {
        guard !clarifications.isEmpty else { return "" }

        let clarificationsXML = clarifications.map { qa in
            """
            <clarified>
            <q>\(qa.question)</q>
            <a>\(qa.answer)</a>
            </clarified>
            """
        }.joined(separator: "\n")

        let responseQualityAnalysis = engagementAnalyzer.analyzeUserResponseQuality(clarifications)
        let adaptationGuidance = engagementAnalyzer.generateAdaptationGuidance(clarifications)

        return """
        <already_clarified>
        The following topics have ALREADY been clarified. This information is KNOWN - do NOT ask about these topics again:
        \(clarificationsXML)
        </already_clarified>

        <user_engagement_pattern>
        \(responseQualityAnalysis)
        ADAPT YOUR QUESTIONS: \(adaptationGuidance)
        </user_engagement_pattern>
        """
    }


    private func buildTaskXML(hasMockups: Bool, hasPreviousClarifications: Bool, includeCodebaseWarning: Bool) -> String {
        let mockupLine = hasMockups ? "\n6. UI/UX FLOWS - What user journeys shown in mockups need clarification?" : ""
        let codebaseWarning = includeCodebaseWarning ? """

        RAG CONTEXT AWARENESS:
        - Limited codebase context is available (5-10 chunks max for optimal quality)
        - DO NOT ask questions requiring comprehensive codebase analysis
        - DO NOT ask about tech stack, language, or patterns visible in codebase
        - Focus on PRODUCT decisions that don't require deep code exploration
        """ : ""

        let clarificationWarning = hasPreviousClarifications ? """

        CRITICAL: Review <already_clarified> section. Those topics are RESOLVED.
        Ask about NEW gaps only. If you ask about an already-clarified topic, you FAIL.
        """ : ""

        return """
        <task>
        You are a PRODUCT MANAGER, not a developer. Ask HIGH-LEVEL PRODUCT questions only.

        ONLY ask about:
        1. BUSINESS GOALS - What problem does this solve? Who benefits? What's the success metric?
        2. USER WORKFLOWS - How do users interact with this feature end-to-end?
        3. SCOPE BOUNDARIES - What's explicitly IN and OUT of scope?
        4. BUSINESS RULES - What policies/constraints govern the behavior?
        5. INTEGRATION POINTS - What other systems/features does this connect to?\(mockupLine)

        NEVER ask about: database schema, API endpoints, mandatory field validation, code patterns, error handling.
        \(codebaseWarning)\(clarificationWarning)
        If all critical gaps are addressed, return empty <questions/>.
        </task>
        """
    }

    private func buildRequestXML(_ request: PRDRequest) -> String {
        let requirementsXML = request.requirements
            .map { "<requirement>\($0.description)</requirement>" }
            .joined(separator: "\n")
        let constraintsXML = request.constraints
            .map { "<constraint>\($0)</constraint>" }
            .joined(separator: "\n")

        return """
        <prd_request>
        <title>\(request.title)</title>
        <description>\(request.description)</description>
        <platform>\(request.platform?.rawValue ?? "not_specified")</platform>
        <requirements>
        \(requirementsXML.isEmpty ? "<none/>" : requirementsXML)
        </requirements>
        <constraints>
        \(constraintsXML.isEmpty ? "<none/>" : constraintsXML)
        </constraints>
        </prd_request>
        """
    }

}

