import Foundation
import Domain

/// Builds LLM prompts for scoring clarification questions
struct CoherenceScoringPromptBuilder: Sendable {

    /// Build prompt to score a SINGLE question (multi-pass mode for small context windows)
    func buildSingleQuestionPrompt(
        question: ClarificationQuestion<String, Int, String>,
        request: PRDRequest,
        codebaseContext: RAGSearchResults?,
        mockupSummaries: [String]
    ) -> String {
        // Minimal context to stay under 4096 tokens
        let contextSummary = buildMinimalContext(codebaseContext: codebaseContext, mockupSummaries: mockupSummaries)

        return """
        \(singleQuestionSystemInstructions)

        <feature>
        \(request.title): \(request.description.prefix(500))
        </feature>

        \(contextSummary)

        <question>
        <text>\(question.question)</text>
        <category>\(question.category.value)</category>
        </question>

        \(singleQuestionResponseFormat)
        """
    }

    func buildPrompt(
        questions: [ClarificationQuestion<String, Int, String>],
        request: PRDRequest,
        codebaseContext: RAGSearchResults?,
        mockupSummaries: [String]
    ) -> String {
        let questionsXML = buildQuestionsXML(questions: questions)
        let contextXML = buildContextXML(codebaseContext: codebaseContext, mockupSummaries: mockupSummaries)

        return """
        \(systemInstructions)

        <feature_description>
        <title>\(request.title)</title>
        <description>\(request.description)</description>
        </feature_description>

        \(contextXML)

        <questions_to_evaluate>
        \(questionsXML)
        </questions_to_evaluate>

        \(responseFormat)
        """
    }

    private func buildQuestionsXML(questions: [ClarificationQuestion<String, Int, String>]) -> String {
        questions.enumerated().map { index, q in
            """
            <question index="\(index)">
            <text>\(q.question)</text>
            <category>\(q.category.value)</category>
            <rationale>\(q.rationale)</rationale>
            </question>
            """
        }.joined(separator: "\n")
    }

    private func buildContextXML(codebaseContext: RAGSearchResults?, mockupSummaries: [String]) -> String {
        var parts: [String] = []
        if let context = codebaseContext {
            parts.append("<codebase_files>\(context.relevantFiles.prefix(5).joined(separator: ", "))</codebase_files>")
        }
        if !mockupSummaries.isEmpty {
            parts.append("<mockups>\(mockupSummaries.joined(separator: "; "))</mockups>")
        }
        return parts.joined(separator: "\n")
    }

    /// Minimal context for single-question scoring (stays under 4096 tokens)
    private func buildMinimalContext(codebaseContext: RAGSearchResults?, mockupSummaries: [String]) -> String {
        var parts: [String] = []
        if let context = codebaseContext, !context.relevantFiles.isEmpty {
            // Only include 3 files max, abbreviated
            let files = context.relevantFiles.prefix(3).joined(separator: ", ")
            parts.append("<context>Files: \(files)</context>")
        }
        if !mockupSummaries.isEmpty {
            // Only include first mockup summary, truncated
            let summary = String(mockupSummaries.first?.prefix(100) ?? "")
            parts.append("<mockup>\(summary)</mockup>")
        }
        return parts.joined(separator: "\n")
    }
}

// MARK: - Prompt Templates
extension CoherenceScoringPromptBuilder {

    private var systemInstructions: String {
        """
        <system>
        You are evaluating clarification questions for a PRD. Score each question on two dimensions:

        1. COHERENCE (0.0-1.0): How relevant is this question to the specific product being built?
           - Score >= 0.9 means the question is highly relevant to THIS specific product
           - Score < 0.9 means the question is too generic or off-topic

        2. EFFECTIVENESS (0.0-1.0): Measured AGAINST THE FEATURE DESCRIPTION below.
           - Score >= 0.8 means the answer will directly improve PRD quality for this feature
           - Score < 0.8 means the question won't meaningfully help define this feature

        Score LOW (< 0.5) for generic, already-answered, or implementation-focused questions.
        Score HIGH (>= 0.8/0.9) for questions addressing gaps in THIS feature description.
        </system>
        """
    }

    /// Compact system instructions for single-question scoring (saves tokens)
    private var singleQuestionSystemInstructions: String {
        """
        Score this PRD clarification question:

        COHERENCE (0-1): Is this a HIGH-LEVEL PRODUCT question? Score HIGH (>=0.9) for business/product gaps. Score LOW (<0.5) for implementation details, developer concerns, or technical minutiae.

        EFFECTIVENESS (0-1): Will the answer help define WHAT to build, not HOW? Score HIGH (>=0.8) for scope, business rules, user needs. Score LOW for code patterns, validation logic, field checks.

        REJECT questions about: mandatory fields, validation rules, code structure, API implementation details, database column names.
        ACCEPT questions about: user workflows, business goals, integration requirements, success criteria, scope boundaries.
        """
    }

    private var responseFormat: String {
        """
        <response_format>
        Return XML with scores for each question:
        <scores>
        <score index="0">
        <coherence>0.0-1.0</coherence>
        <effectiveness>0.0-1.0</effectiveness>
        <reasoning>Brief explanation</reasoning>
        </score>
        </scores>
        </response_format>
        """
    }

    /// Compact response format for single-question scoring
    private var singleQuestionResponseFormat: String {
        """
        Reply with ONLY:
        <scores>
        <score index="0">
        <coherence>0.0-1.0</coherence>
        <effectiveness>0.0-1.0</effectiveness>
        <reasoning>One sentence</reasoning>
        </score>
        </scores>
        """
    }
}
