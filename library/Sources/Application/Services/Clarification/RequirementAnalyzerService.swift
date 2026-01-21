import Foundation
import Domain

/// Analyzes PRD requirements and generates clarification questions
/// ALWAYS uses AI to analyze the request - no hardcoded fallbacks
/// Tracks all LLM calls to DB via intelligenceTracker
/// Applies Chain of Verification to all LLM responses
public struct RequirementAnalyzerService: Sendable {
    private let aiProvider: AIProviderPort
    private let intelligenceTracker: IntelligenceTrackerService?
    private let verifier: LLMResponseVerifier?
    private let promptBuilder: AnalysisPromptBuilder

    public init(
        aiProvider: AIProviderPort,
        intelligenceTracker: IntelligenceTrackerService? = nil,
        verifier: LLMResponseVerifier? = nil
    ) {
        self.aiProvider = aiProvider
        self.intelligenceTracker = intelligenceTracker
        self.verifier = verifier
        self.promptBuilder = AnalysisPromptBuilder()
    }

    /// Analyze requirements and generate gap analysis using AI
    public func analyzeRequirements(
        _ request: PRDRequest,
        codebaseContext: RAGSearchResults? = nil
    ) async throws -> GapAnalysisResult<String, Int, String> {
        print("🔬 [RequirementAnalyzer] Starting AI analysis for: \(request.title)")

        let questions = try await analyzeAndGenerateQuestions(request, codebaseContext: codebaseContext)
        let completenessScore = calculateCompletenessScore(request: request, questions: questions)

        print("📊 [RequirementAnalyzer] Analysis complete:")
        print("  - Questions generated: \(questions.count)")
        print("  - Completeness score: \(completenessScore)")

        return GapAnalysisResult(
            completenessScore: completenessScore,
            detectedGaps: questions.map { $0.detectedGap },
            questions: questions,
            confidence: 0.9
        )
    }

    /// Generate clarification questions using AI analysis
    /// - Parameters:
    ///   - request: The PRD request to analyze
    ///   - codebaseContext: Optional RAG results from codebase
    ///   - mockupSummaries: Summaries from mockup analysis (UI components, flows)
    ///   - previousClarifications: Q&A pairs already collected (to avoid re-asking)
    public func analyzeAndGenerateQuestions(
        _ request: PRDRequest,
        codebaseContext: RAGSearchResults? = nil,
        mockupSummaries: [String] = [],
        previousClarifications: [(question: String, answer: String)] = []
    ) async throws -> [ClarificationQuestion<String, Int, String>] {
        if let context = codebaseContext, !context.relevantChunks.isEmpty {
            print("🔍 [RequirementAnalyzer] AI analysis WITH codebase context")
            print("📋 [RequirementAnalyzer] Previous clarifications: \(previousClarifications.count)")
            return try await generateQuestionsWithCodebase(
                request: request,
                codebaseContext: context,
                mockupSummaries: mockupSummaries,
                previousClarifications: previousClarifications
            )
        } else {
            print("🔍 [RequirementAnalyzer] AI analysis WITHOUT codebase context")
            print("📋 [RequirementAnalyzer] Previous clarifications: \(previousClarifications.count)")
            return try await generateQuestionsWithoutCodebase(
                request: request,
                mockupSummaries: mockupSummaries,
                previousClarifications: previousClarifications
            )
        }
    }

    private func generateQuestionsWithCodebase(
        request: PRDRequest,
        codebaseContext: RAGSearchResults,
        mockupSummaries: [String],
        previousClarifications: [(question: String, answer: String)]
    ) async throws -> [ClarificationQuestion<String, Int, String>] {
        // Get context window size from AI provider
        let contextWindowSize = aiProvider.contextWindowSize
        print("📏 [RequirementAnalyzer] Using context window size: \(contextWindowSize) tokens (provider: \(aiProvider.providerName))")

        let prompt = promptBuilder.buildCodebaseAwarePrompt(
            request: request,
            codebaseContext: codebaseContext,
            mockupSummaries: mockupSummaries,
            previousClarifications: previousClarifications,
            contextWindowSize: contextWindowSize
        )
        return try await executeAnalysis(prompt: prompt, hasCodebase: true)
    }

    private func generateQuestionsWithoutCodebase(
        request: PRDRequest,
        mockupSummaries: [String],
        previousClarifications: [(question: String, answer: String)]
    ) async throws -> [ClarificationQuestion<String, Int, String>] {
        // Get context window size from AI provider
        let contextWindowSize = aiProvider.contextWindowSize
        print("📏 [RequirementAnalyzer] Using context window size: \(contextWindowSize) tokens (provider: \(aiProvider.providerName))")

        let prompt = promptBuilder.buildStandalonePrompt(
            request: request,
            mockupSummaries: mockupSummaries,
            previousClarifications: previousClarifications,
            contextWindowSize: contextWindowSize
        )
        return try await executeAnalysis(prompt: prompt, hasCodebase: false)
    }

    private func executeAnalysis(prompt: String, hasCodebase: Bool) async throws -> [ClarificationQuestion<String, Int, String>] {
        let startTime = Date()
        let response = try await aiProvider.generateText(prompt: prompt, temperature: 0.3)
        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

        // Apply Chain of Verification to validate response
        if let verifier = verifier {
            let context = hasCodebase ? "Requirement analysis with codebase context" : "Standalone requirement analysis"
            let verificationResult = try await verifier.verifyResponse(
                prompt: prompt,
                response: response,
                context: context,
                verificationType: .questionRelevance
            )

            if !verificationResult.verified {
                print("⚠️ [RequirementAnalyzer] Verification failed - using response with caution")
                // Continue with response but log the failure
            }
        }

        await trackAnalysisLLMCall(prompt: prompt, response: response, latencyMs: latencyMs, hasCodebase: hasCodebase)
        return parseXMLResponse(response)
    }

    private func trackAnalysisLLMCall(prompt: String, response: String, latencyMs: Int, hasCodebase: Bool) async {
        guard let tracker = intelligenceTracker else {
            print("⚠️ [RequirementAnalyzer] No intelligenceTracker - LLM call NOT tracked to DB")
            return
        }

        do {
            let templateName = hasCodebase ? "analysis_with_codebase" : "analysis_standalone"
            _ = try await tracker.trackLLMInteraction(
                prdId: nil,
                sectionId: nil,
                purpose: .requirementAnalysis,
                contextType: hasCodebase ? .codebaseEnriched : .initial,
                promptTemplate: templateName,
                actualPrompt: prompt,
                systemInstructions: nil,
                llmModel: aiProvider.modelName,
                provider: aiProvider.providerName,
                parameters: LLMParameters(temperature: 0.3),
                response: response,
                tokensPrompt: nil,
                tokensResponse: nil,
                latencyMs: latencyMs,
                thinkingStrategy: nil,
                thinkingDepth: nil
            )
            print("✅ [Intelligence] Tracked analysis LLM call (\(templateName))")
        } catch {
            print("❌ [Intelligence] Failed to track analysis LLM call: \(error)")
        }
    }

    private func parseXMLResponse(_ response: String) -> [ClarificationQuestion<String, Int, String>] {
        var questions: [ClarificationQuestion<String, Int, String>] = []
        let questionPattern = "<question>(.*?)</question>"
        guard let regex = try? NSRegularExpression(pattern: questionPattern, options: .dotMatchesLineSeparators) else {
            print("⚠️ [RequirementAnalyzer] Failed to create regex")
            return []
        }

        let range = NSRange(response.startIndex..., in: response)
        let matches = regex.matches(in: response, options: [], range: range)

        for match in matches {
            guard let questionRange = Range(match.range(at: 1), in: response) else { continue }
            let questionBlock = String(response[questionRange])

            let category = extractXMLValue(from: questionBlock, tag: "category") ?? "technical"
            let text = extractXMLValue(from: questionBlock, tag: "text") ?? ""
            let rationale = extractXMLValue(from: questionBlock, tag: "rationale") ?? ""
            let priorityStr = extractXMLValue(from: questionBlock, tag: "priority") ?? "5"
            let priority = Int(priorityStr) ?? 5
            let examples = extractExamples(from: questionBlock)

            guard !text.isEmpty else { continue }

            questions.append(ClarificationQuestion(
                category: QuestionCategory(category),
                question: text,
                rationale: rationale,
                examples: examples,
                priority: QuestionPriority(min(max(priority, 1), 10)),
                detectedGap: GapType("gap_\(category)")
            ))
        }

        print("✅ [RequirementAnalyzer] Parsed \(questions.count) questions from XML")
        return questions
    }

    private func extractExamples(from xml: String) -> [String] {
        var examples: [String] = []
        let examplePattern = "<example>(.*?)</example>"
        guard let regex = try? NSRegularExpression(pattern: examplePattern, options: .dotMatchesLineSeparators) else {
            return []
        }

        let range = NSRange(xml.startIndex..., in: xml)
        let matches = regex.matches(in: xml, options: [], range: range)

        for match in matches {
            guard let exampleRange = Range(match.range(at: 1), in: xml) else { continue }
            let example = String(xml[exampleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !example.isEmpty {
                examples.append(example)
            }
        }

        return examples
    }

    private func extractXMLValue(from xml: String, tag: String) -> String? {
        let pattern = "<\(tag)>(.*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
              let match = regex.firstMatch(in: xml, options: [], range: NSRange(xml.startIndex..., in: xml)),
              let range = Range(match.range(at: 1), in: xml) else {
            return nil
        }
        return String(xml[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func calculateCompletenessScore(
        request: PRDRequest,
        questions: [ClarificationQuestion<String, Int, String>]
    ) -> Double {
        var score = 0.3
        if !request.description.isEmpty { score += 0.1 }
        if !request.requirements.isEmpty { score += 0.1 }
        if !request.constraints.isEmpty { score += 0.1 }
        if request.codebaseId != nil { score += 0.1 }
        if request.mockupFileIds != nil { score += 0.1 }

        let highPriorityCount = questions.filter { $0.priority.value >= 8 }.count
        score -= Double(highPriorityCount) * 0.1

        return max(0.0, min(1.0, score))
    }
}
