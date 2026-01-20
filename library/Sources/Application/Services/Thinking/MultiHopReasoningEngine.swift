import Foundation
import Domain

/// Multi-hop reasoning with iterative refinement and verification
/// Following Single Responsibility: Orchestrates multi-step reasoning
public struct MultiHopReasoningEngine: Sendable {
    private let aiProvider: AIProviderPort
    private let verifier: ReasoningVerifier
    private let promptBuilder: StructuredCoTPromptBuilder
    private let contextBuilder: ReasoningContextBuilder

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
        self.verifier = ReasoningVerifier(aiProvider: aiProvider)
        self.promptBuilder = StructuredCoTPromptBuilder()
        self.contextBuilder = ReasoningContextBuilder()
    }

    /// Execute multi-hop reasoning with verification
    public func reason(
        problem: String,
        context: String,
        constraints: [String],
        maxHops: Int = 3
    ) async throws -> VerifiedThoughtChain {
        var currentContext = context
        var allHops: [ReasoningHop] = []
        var unresolvedQuestions: [String] = [problem]

        for hopNumber in 0..<maxHops {
            guard !unresolvedQuestions.isEmpty else { break }

            let currentQuestion = unresolvedQuestions.removeFirst()
            let (verifiedHop, updatedContext) = try await processReasoningHop(
                question: currentQuestion,
                context: currentContext,
                originalContext: context,
                constraints: constraints,
                hopNumber: hopNumber
            )

            allHops.append(verifiedHop)
            currentContext = updatedContext

            let newQuestions = contextBuilder.extractUnresolvedQuestions(from: verifiedHop)
            unresolvedQuestions.append(contentsOf: newQuestions)

            if shouldConclude(hop: verifiedHop, unresolvedQuestions: unresolvedQuestions) {
                break
            }
        }

        return try await synthesizeChain(
            hops: allHops,
            originalProblem: problem,
            finalContext: currentContext
        )
    }

    private func processReasoningHop(
        question: String,
        context: String,
        originalContext: String,
        constraints: [String],
        hopNumber: Int
    ) async throws -> (ReasoningHop, String) {
        let hop = try await performReasoningHop(
            question: question,
            context: context,
            constraints: constraints,
            hopNumber: hopNumber
        )

        let verification = try await verifier.verify(
            hop: hop,
            originalContext: originalContext
        )

        if !verification.isValid {
            let correctedHop = try await selfCorrect(
                hop: hop,
                verification: verification,
                context: context,
                constraints: constraints
            )
            return (correctedHop, contextBuilder.appendHop(context, hop: correctedHop))
        } else {
            return (hop, contextBuilder.appendHop(context, hop: hop))
        }
    }

    private func shouldConclude(hop: ReasoningHop, unresolvedQuestions: [String]) -> Bool {
        hop.confidence > 0.9 && unresolvedQuestions.isEmpty
    }

    // MARK: - Private Methods

    private func performReasoningHop(
        question: String,
        context: String,
        constraints: [String],
        hopNumber: Int
    ) async throws -> ReasoningHop {
        let prompt = promptBuilder.buildPrompt(
            problem: "Step \(hopNumber + 1): \(question)",
            context: context,
            constraints: constraints
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.3 // Lower temp for reliability
        )

        let parser = StructuredCoTParser()
        let parsed = parser.parse(response)

        return ReasoningHop(
            id: UUID(),
            hopNumber: hopNumber,
            question: question,
            thoughts: parsed.thoughts,
            assumptions: parsed.assumptions,
            inferences: parsed.inferences,
            conclusion: parsed.conclusion,
            confidence: parsed.confidence,
            sourceContext: context,
            rawResponse: response
        )
    }

    private func selfCorrect(
        hop: ReasoningHop,
        verification: VerificationResult,
        context: String,
        constraints: [String]
    ) async throws -> ReasoningHop {
        let prompt = buildCorrectionPrompt(
            conclusion: hop.conclusion,
            issues: verification.issues,
            context: context
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.2
        )

        let parsed = StructuredCoTParser().parse(response)

        return createCorrectedHop(
            original: hop,
            parsed: parsed,
            context: context,
            rawResponse: response
        )
    }

    private func buildCorrectionPrompt(
        conclusion: String,
        issues: [String],
        context: String
    ) -> String {
        """
        The following reasoning contains issues that need correction:

        <original_reasoning>
        \(conclusion)
        </original_reasoning>

        <identified_issues>
        \(issues.map { "- \($0)" }.joined(separator: "\n"))
        </identified_issues>

        <context>
        \(context)
        </context>

        Please provide corrected reasoning that:
        1. Addresses all identified issues
        2. Stays grounded in the provided context
        3. Uses only verifiable facts
        4. Clearly marks any remaining assumptions

        Provide corrected reasoning with the same structured format.
        """
    }

    private func createCorrectedHop(
        original: ReasoningHop,
        parsed: ParsedReasoning,
        context: String,
        rawResponse: String
    ) -> ReasoningHop {
        ReasoningHop(
            id: UUID(),
            hopNumber: original.hopNumber,
            question: original.question,
            thoughts: parsed.thoughts,
            assumptions: parsed.assumptions,
            inferences: parsed.inferences,
            conclusion: parsed.conclusion,
            confidence: min(parsed.confidence, 0.85),
            sourceContext: context,
            rawResponse: rawResponse,
            wasCorrected: true
        )
    }


    private func synthesizeChain(
        hops: [ReasoningHop],
        originalProblem: String,
        finalContext: String
    ) async throws -> VerifiedThoughtChain {
        let prompt = buildSynthesisPrompt(problem: originalProblem, hops: hops)
        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.2
        )

        let parsed = StructuredCoTParser().parse(response)
        let calibratedConfidence = calibrateConfidence(
            hops: hops,
            synthesisConfidence: parsed.confidence
        )

        return buildFinalChain(
            problem: originalProblem,
            hops: hops,
            conclusion: parsed.conclusion,
            confidence: calibratedConfidence
        )
    }

    private func buildSynthesisPrompt(problem: String, hops: [ReasoningHop]) -> String {
        """
        Synthesize the following multi-step reasoning into a final conclusion:

        <original_problem>
        \(problem)
        </original_problem>

        <reasoning_steps>
        \(hops.enumerated().map { index, hop in
            "Step \(index + 1): \(hop.question)\nConclusion: \(hop.conclusion)"
        }.joined(separator: "\n\n"))
        </reasoning_steps>

        Provide:
        1. Final synthesized conclusion
        2. Overall confidence level (0.0-1.0)
        3. Any remaining caveats or limitations

        Format:
        CONCLUSION: [final answer]
        CONFIDENCE: [0.0-1.0]
        CAVEATS: [list any limitations]
        """
    }

    private func buildFinalChain(
        problem: String,
        hops: [ReasoningHop],
        conclusion: String,
        confidence: Double
    ) -> VerifiedThoughtChain {
        VerifiedThoughtChain(
            id: UUID(),
            problem: problem,
            hops: hops,
            thoughts: hops.flatMap(\.thoughts),
            conclusion: conclusion,
            confidence: confidence,
            assumptions: hops.flatMap(\.assumptions),
            timestamp: Date(),
            wasVerified: true
        )
    }

    private func calibrateConfidence(
        hops: [ReasoningHop],
        synthesisConfidence: Double
    ) -> Double {
        let calibrator = ConfidenceCalibrator()
        return calibrator.calibrate(
            hops: hops,
            synthesisConfidence: synthesisConfidence
        )
    }
}

