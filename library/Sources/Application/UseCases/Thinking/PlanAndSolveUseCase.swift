import Foundation
import Domain

/// Plan-and-Solve pattern: Explicit planning phase before execution
///
/// **Professional Design:**
/// - TRM-powered refinement with intelligent halting
/// - Configurable quality thresholds and iteration limits
/// - Convergence detection instead of arbitrary limits
///
/// Single Responsibility: Orchestrates planning, execution, and verification
public struct PlanAndSolveUseCase: Sendable {
    private let aiProvider: AIProviderPort
    private let planParser: PlanParser
    private let planExecutor: PlanExecutor
    private let planVerifier: PlanVerifier
    private let trmEnhancement: TRMEnhancementService
    private let planRefiner: PlanRefiner

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
        self.planParser = PlanParser()
        self.planExecutor = PlanExecutor(aiProvider: aiProvider)
        self.planVerifier = PlanVerifier(aiProvider: aiProvider)
        self.trmEnhancement = TRMEnhancementService(aiProvider: aiProvider)
        self.planRefiner = PlanRefiner(aiProvider: aiProvider)
    }

    /// Execute Plan-and-Solve with decomposition and verification
    ///
    /// **Professional Parameters:**
    /// - `qualityTarget`: Target confidence score (0.5-1.0, default 0.90)
    /// - `config`: TRM configuration for intelligent halting (optional)
    ///
    /// **Behavior:**
    /// - Uses TRM enhancement for convergence detection when config provided
    /// - Halts on oscillation or diminishing returns
    /// - More efficient than fixed iteration limits
    public func execute(
        problem: String,
        context: String = "",
        constraints: [String] = [],
        qualityTarget: Double = 0.90,
        config: TRMConfig? = nil
    ) async throws -> PlanAndSolveResult {
        let initialResult = try await executeInitialPlanAndSolve(
            problem: problem,
            context: context,
            constraints: constraints
        )

        // Use TRM enhancement if config provided and below quality target
        if let config = config, initialResult.averageConfidence < qualityTarget {
            return try await applyTRMEnhancement(
                to: initialResult,
                problem: problem,
                context: context,
                constraints: constraints,
                config: config
            )
        }

        return initialResult
    }

    // MARK: - Private Methods

    /// Execute initial Plan-and-Solve (first attempt)
    ///
    /// **3R's Justification - Reliability & Reusability:**
    /// - Testable: Can verify initial planning quality in isolation
    /// - Reusable: Both direct execution and TRM refinement need this
    /// - Clear boundary: Setup phase separate from refinement
    private func executeInitialPlanAndSolve(
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> PlanAndSolveResult {
        let plan = try await createPlan(
            problem: problem,
            context: context,
            constraints: constraints
        )

        let executionResults = try await planExecutor.execute(
            plan: plan,
            initialContext: context
        )

        let verification = try await planVerifier.verify(
            problem: problem,
            plan: plan,
            results: executionResults,
            context: context
        )

        return synthesizeResult(
            problem: problem,
            plan: plan,
            executionResults: executionResults,
            verification: verification
        )
    }

    /// Apply TRM enhancement for intelligent iterative refinement
    ///
    /// **3R's Justification - Readability & Reusability:**
    /// - Readability: Encapsulates closure definition complexity
    /// - Reusability: Standard pattern for TRM-enhancing PlanAndSolve
    /// - Testable: Can test enhancement behavior in isolation
    private func applyTRMEnhancement(
        to initialResult: PlanAndSolveResult,
        problem: String,
        context: String,
        constraints: [String],
        config: TRMConfig
    ) async throws -> PlanAndSolveResult {
        let refiner: Refiner<PlanAndSolveResult> = { previousResult, prob, ctx in
            try await self.refinePlanAndSolveResult(
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

    /// Refine PlanAndSolveResult using PlanRefiner service
    ///
    /// **3R's Justification - Reusability:**
    /// - Delegates to reusable PlanRefiner service
    /// - Testable through service interface
    private func refinePlanAndSolveResult(
        previousResult: PlanAndSolveResult,
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> PlanAndSolveResult {
        return try await planRefiner.refine(
            previousResult: previousResult,
            problem: problem,
            context: context,
            constraints: constraints
        )
    }

    private func createPlan(
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> ExecutionPlan {
        let prompt = buildPlanningPrompt(
            problem: problem,
            context: context,
            constraints: constraints
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.3
        )

        return planParser.parse(response: response, problem: problem)
    }

    private func buildPlanningPrompt(
        problem: String,
        context: String,
        constraints: [String]
    ) -> String {
        """
        Create a detailed plan to solve this problem:

        <problem>
        \(problem)
        </problem>

        <context>
        \(context)
        </context>

        <constraints>
        \(constraints.map { "- \($0)" }.joined(separator: "\n"))
        </constraints>

        Provide a step-by-step plan:

        1. Decompose the problem into subproblems
        2. Order steps logically (dependencies first)
        3. Identify required information for each step
        4. Note potential challenges

        Format:
        STEP_N: [description]
        REQUIRES: [what's needed for this step]
        PRODUCES: [what this step delivers]
        CHALLENGES: [potential issues]
        """
    }

    private func synthesizeResult(
        problem: String,
        plan: ExecutionPlan,
        executionResults: [StepResult],
        verification: PlanVerification
    ) -> PlanAndSolveResult {
        let finalOutput = executionResults.last?.output ?? "No conclusion"

        let totalConfidence = executionResults.map(\.confidence).reduce(0.0, +)
        let averageConfidence = totalConfidence / Double(executionResults.count)

        return PlanAndSolveResult(
            problem: problem,
            plan: plan,
            executionResults: executionResults,
            verification: verification,
            finalOutput: finalOutput,
            averageConfidence: averageConfidence
        )
    }
}
