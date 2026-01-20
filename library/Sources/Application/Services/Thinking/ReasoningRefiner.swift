import Foundation
import Domain

/// Refines reasoning chains to address identified issues
/// Following Single Responsibility: Reasoning refinement only
/// Reusable component following 3Rs principles
struct ReasoningRefiner {
    private let aiProvider: AIProviderPort

    init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Refine reasoning chain to address specific issues
    func refine(
        chain: VerifiedThoughtChain,
        problem: String,
        context: String,
        issues: [String]
    ) async throws -> VerifiedThoughtChain {
        let prompt = buildRefinementPrompt(
            problem: problem,
            conclusion: chain.conclusion,
            issues: issues,
            context: context
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.2
        )

        let parsed = parseResponse(response)
        let refinedHop = createRefinementHop(
            from: parsed,
            hopNumber: chain.hops.count,
            context: context
        )

        return buildRefinedChain(
            original: chain,
            refinedHop: refinedHop,
            parsed: parsed
        )
    }

    // MARK: - Private Methods

    private func buildRefinementPrompt(
        problem: String,
        conclusion: String,
        issues: [String],
        context: String
    ) -> String {
        """
        Refine the following reasoning to address identified issues:

        <original_problem>
        \(problem)
        </original_problem>

        <current_reasoning>
        \(conclusion)
        </current_reasoning>

        <issues_to_address>
        \(issues.map { "- \($0)" }.joined(separator: "\n"))
        </issues_to_address>

        <context>
        \(context)
        </context>

        Provide refined reasoning that:
        1. Addresses all identified issues
        2. Maintains logical consistency
        3. Grounds all claims in context
        4. Achieves higher confidence

        Use structured format with explicit reasoning steps.
        """
    }

    private func parseResponse(_ response: String) -> ParsedReasoning {
        let parser = StructuredCoTParser()
        return parser.parse(response)
    }

    private func createRefinementHop(
        from parsed: ParsedReasoning,
        hopNumber: Int,
        context: String
    ) -> ReasoningHop {
        ReasoningHop(
            id: UUID(),
            hopNumber: hopNumber,
            question: "Refinement iteration",
            thoughts: parsed.thoughts,
            assumptions: parsed.assumptions,
            inferences: parsed.inferences,
            conclusion: parsed.conclusion,
            confidence: parsed.confidence,
            sourceContext: context,
            rawResponse: parsed.rawResponse,
            wasCorrected: true
        )
    }

    private func buildRefinedChain(
        original: VerifiedThoughtChain,
        refinedHop: ReasoningHop,
        parsed: ParsedReasoning
    ) -> VerifiedThoughtChain {
        VerifiedThoughtChain(
            id: original.id,
            problem: original.problem,
            hops: original.hops + [refinedHop],
            thoughts: original.thoughts + parsed.thoughts,
            conclusion: parsed.conclusion,
            confidence: min(parsed.confidence, 0.92),
            assumptions: original.assumptions + parsed.assumptions,
            timestamp: Date(),
            wasVerified: true
        )
    }
}
