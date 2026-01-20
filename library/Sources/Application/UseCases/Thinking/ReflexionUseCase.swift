import Foundation
import Domain

/// Reflexion pattern: Self-reflection and iterative improvement with memory
///
/// **Professional Design:**
/// - TRM-powered refinement with intelligent halting
/// - Configurable quality thresholds and iteration limits
/// - Convergence detection instead of arbitrary limits
///
/// Single Responsibility: Orchestrates reflection-driven improvement cycles
public struct ReflexionUseCase: Sendable {
    private let aiProvider: AIProviderPort
    private let promptBuilder: StructuredCoTPromptBuilder
    private let parser: StructuredCoTParser
    private let reflectionAnalyzer: ReflectionAnalyzer
    private let memoryFormatter: ReflectionMemoryFormatter
    private let trmEnhancement: TRMEnhancementService

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
        self.promptBuilder = StructuredCoTPromptBuilder()
        self.parser = StructuredCoTParser()
        self.reflectionAnalyzer = ReflectionAnalyzer(aiProvider: aiProvider)
        self.memoryFormatter = ReflectionMemoryFormatter()
        self.trmEnhancement = TRMEnhancementService(aiProvider: aiProvider)
    }

    /// Execute Reflexion with self-evaluation and improvement
    ///
    /// **Professional Parameters:**
    /// - `qualityTarget`: Target quality score (0.5-1.0, default 0.90)
    /// - `config`: TRM configuration for intelligent halting (default: balanced)
    ///
    /// **Behavior:**
    /// - Uses TRM enhancement for convergence detection
    /// - Halts on oscillation or diminishing returns
    /// - More efficient than fixed iteration limits
    public func execute(
        problem: String,
        context: String = "",
        constraints: [String] = [],
        qualityTarget: Double = 0.90,
        config: TRMConfig = .balanced
    ) async throws -> ReflexionResult {
        let initialResult = try await generateInitialReflexion(
            problem: problem,
            context: context,
            constraints: constraints
        )

        guard initialResult.confidence < qualityTarget else {
            return initialResult
        }

        return try await applyTRMEnhancement(
            to: initialResult,
            problem: problem,
            context: context,
            constraints: constraints,
            config: config
        )
    }

    // MARK: - Private Methods

    /// Generate initial Reflexion result (first attempt + reflection)
    ///
    /// **3R's Justification - Reliability & Reusability:**
    /// - Testable: Can verify initial attempt quality in isolation
    /// - Reusable: Other Reflexion variants may need initial generation
    /// - Clear boundary: Setup phase separate from refinement
    private func generateInitialReflexion(
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> ReflexionResult {
        let attempt = try await generateAttempt(
            problem: problem,
            context: context,
            constraints: constraints,
            reflectionMemory: [],
            iteration: 0
        )

        let reflection = try await reflectionAnalyzer.reflect(
            on: attempt,
            problem: problem,
            context: context,
            iteration: 0
        )

        return ReflexionResult(
            problem: problem,
            finalConclusion: attempt.conclusion,
            finalQualityScore: reflection.qualityScore,
            reflectionMemory: [reflection],
            iterationsUsed: 1,
            improvementTrajectory: [reflection.qualityScore]
        )
    }

    /// Apply TRM enhancement for intelligent iterative refinement
    ///
    /// **3R's Justification - Readability & Reusability:**
    /// - Readability: Encapsulates closure definition complexity
    /// - Reusability: Standard pattern for TRM-enhancing any Reflexion
    /// - Testable: Can test enhancement behavior in isolation
    private func applyTRMEnhancement(
        to initialResult: ReflexionResult,
        problem: String,
        context: String,
        constraints: [String],
        config: TRMConfig
    ) async throws -> ReflexionResult {
        let refiner: Refiner<ReflexionResult> = { previousResult, prob, ctx in
            try await self.refineReflexionResult(
                previousResult: previousResult,
                problem: prob,
                context: ctx,
                constraints: constraints
            )
        }

        let enhanced = try await trmEnhancement.enhance(
            baseResult: initialResult,
            problem: problem,
            context: context,
            refiner: refiner,
            config: config
        )

        return enhanced.result
    }

    /// Refine ReflexionResult by generating new attempt based on reflection memory
    ///
    /// **3R's Justification - Reusability:**
    /// - Encapsulates single refinement cycle logic
    /// - Reusable by TRM enhancement service
    /// - Testable in isolation
    private func refineReflexionResult(
        previousResult: ReflexionResult,
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> ReflexionResult {
        let nextIteration = previousResult.iterationsUsed

        // Generate new attempt using reflection memory
        let attempt = try await generateAttempt(
            problem: problem,
            context: context,
            constraints: constraints,
            reflectionMemory: previousResult.reflectionMemory,
            iteration: nextIteration
        )

        // Reflect on new attempt
        let reflection = try await reflectionAnalyzer.reflect(
            on: attempt,
            problem: problem,
            context: context,
            iteration: nextIteration
        )

        // Accumulate reflection memory
        var updatedMemory = previousResult.reflectionMemory
        updatedMemory.append(reflection)

        // Update improvement trajectory
        var updatedTrajectory = previousResult.improvementTrajectory
        updatedTrajectory.append(reflection.qualityScore)

        return ReflexionResult(
            problem: problem,
            finalConclusion: attempt.conclusion,
            finalQualityScore: reflection.qualityScore,
            reflectionMemory: updatedMemory,
            iterationsUsed: nextIteration + 1,
            improvementTrajectory: updatedTrajectory
        )
    }

    private func generateAttempt(
        problem: String,
        context: String,
        constraints: [String],
        reflectionMemory: [ReflectionEntry],
        iteration: Int
    ) async throws -> ThoughtChain {
        let prompt = buildAttemptPrompt(
            problem: problem,
            context: context,
            constraints: constraints,
            reflectionMemory: reflectionMemory,
            iteration: iteration
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.7
        )

        let parsed = parser.parse(response)

        return ThoughtChain(
            id: UUID(),
            problem: problem,
            thoughts: parsed.thoughts,
            conclusion: parsed.conclusion,
            confidence: parsed.confidence,
            alternatives: [],
            assumptions: parsed.assumptions,
            timestamp: Date()
        )
    }

    private func buildAttemptPrompt(
        problem: String,
        context: String,
        constraints: [String],
        reflectionMemory: [ReflectionEntry],
        iteration: Int
    ) -> String {
        let memoryContext = memoryFormatter.format(reflectionMemory)
        let iterationGuidance = iteration == 0 ? "" : "\nThis is attempt #\(iteration + 1). Use insights from previous reflections."

        return """
        Solve the following problem:\(iterationGuidance)

        <problem>
        \(problem)
        </problem>

        <context>
        \(context)
        </context>

        <constraints>
        \(constraints.map { "- \($0)" }.joined(separator: "\n"))
        </constraints>
        \(memoryContext)

        Provide structured reasoning with:
        - Clear thought process
        - Explicit assumptions
        - Logical inferences
        - Confident conclusion
        """
    }

    private func synthesizeResult(
        problem: String,
        finalAttempt: ThoughtChain?,
        reflectionMemory: [ReflectionEntry],
        iterations: Int
    ) -> ReflexionResult {
        guard let final = finalAttempt else {
            return ReflexionResult(
                problem: problem,
                finalConclusion: "No solution reached",
                finalQualityScore: 0.0,
                reflectionMemory: reflectionMemory,
                iterationsUsed: iterations,
                improvementTrajectory: []
            )
        }

        return ReflexionResult(
            problem: problem,
            finalConclusion: final.conclusion,
            finalQualityScore: reflectionMemory.last?.qualityScore ?? 0.0,
            reflectionMemory: reflectionMemory,
            iterationsUsed: iterations,
            improvementTrajectory: memoryFormatter.improvementTrajectory(reflectionMemory)
        )
    }
}
