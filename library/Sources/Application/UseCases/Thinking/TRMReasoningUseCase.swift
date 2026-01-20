import Foundation
import Domain

/// TRM (Tiny Recursion Model) Reasoning Use Case
///
/// Orchestrates recursive refinement process:
/// 1. Generate initial prediction
/// 2. Iteratively refine latent state (z) and prediction (y)
/// 3. Halt when confidence threshold met or max iterations reached
///
/// **Based on:** Samsung TRM paper (arXiv 2510.04871)
/// "Less is More: Recursive Reasoning with Tiny Networks"
///
/// **Usage:**
/// ```swift
/// let useCase = TRMReasoningUseCase(aiProvider: provider)
/// let result = try await useCase.execute(
///     problem: "What is 2+2?",
///     context: "",
///     constraints: [],
///     maxIterations: 16,
///     confidenceThreshold: 0.9
/// )
/// ```
public struct TRMReasoningUseCase: Sendable {
    private let aiProvider: AIProviderPort
    private let iterationEngine: TRMIterationEngine
    private let haltingEvaluator: TRMHaltingEvaluator
    private let stateTracker: TRMStateTracker
    private let promptBuilder: TRMPromptBuilder

    public init(
        aiProvider: AIProviderPort,
        iterationEngine: TRMIterationEngine? = nil,
        haltingEvaluator: TRMHaltingEvaluator = TRMHaltingEvaluator(),
        stateTracker: TRMStateTracker = TRMStateTracker(),
        promptBuilder: TRMPromptBuilder = TRMPromptBuilder()
    ) {
        self.aiProvider = aiProvider
        self.iterationEngine = iterationEngine ?? TRMIterationEngine(
            aiProvider: aiProvider
        )
        self.haltingEvaluator = haltingEvaluator
        self.stateTracker = stateTracker
        self.promptBuilder = promptBuilder
    }

    // MARK: - Public Methods

    /// Execute TRM recursive refinement
    ///
    /// - Parameters:
    ///   - problem: Problem statement
    ///   - context: Additional context
    ///   - constraints: Constraints to consider
    ///   - maxIterations: Maximum refinement iterations (default 16)
    ///   - confidenceThreshold: Confidence threshold for halting (default 0.9)
    /// - Returns: Complete refinement chain
    public func execute(
        problem: String,
        context: String = "",
        constraints: [String] = [],
        maxIterations: Int = 16,
        confidenceThreshold: Double = 0.9
    ) async throws -> TRMRefinementChain {
        let initialPrediction = try await generateInitialPrediction(
            problem: problem,
            context: context,
            constraints: constraints
        )
        var currentState = RefinementState.initial()
        var currentPrediction = initialPrediction.prediction
        var currentConfidence = initialPrediction.confidence
        var iterations: [TRMIteration] = []
        var confidenceTrajectory: [Double] = [initialPrediction.confidence]

        for iterationNumber in 1...maxIterations {
            let result = try await performSingleIteration(
                iterationNumber: iterationNumber, problem: problem, context: context,
                currentPrediction: currentPrediction, currentConfidence: currentConfidence,
                currentState: currentState)

            iterations.append(result.iteration)
            confidenceTrajectory.append(result.confidence)
            currentPrediction = result.prediction
            currentConfidence = result.confidence
            currentState = result.state

            if shouldHalt(result.iteration, confidenceTrajectory, confidenceThreshold, maxIterations) {
                return buildChain(problem, initialPrediction.prediction, iterations,
                    currentPrediction, currentConfidence,
                    haltedEarly: iterationNumber < maxIterations, confidenceTrajectory)
            }
        }
        return buildChain(problem, initialPrediction.prediction, iterations,
            currentPrediction, currentConfidence, haltedEarly: false, confidenceTrajectory)
    }

    /// Build refinement chain from final state
    ///
    /// **3R's Justification - Readability:**
    /// - Reduces visual noise in main execute() method
    /// - Called twice with similar but slightly different parameters
    /// - Clear intent: "build the final result chain"
    private func buildChain(
        _ problem: String,
        _ initialPrediction: String,
        _ iterations: [TRMIteration],
        _ finalPrediction: String,
        _ finalConfidence: Double,
        haltedEarly: Bool,
        _ trajectory: [Double]
    ) -> TRMRefinementChain {
        return buildRefinementChain(
            problem: problem,
            initialPrediction: initialPrediction,
            iterations: iterations,
            finalPrediction: finalPrediction,
            finalConfidence: finalConfidence,
            haltedEarly: haltedEarly,
            convergenceTrajectory: trajectory
        )
    }

    /// Perform single TRM refinement iteration
    ///
    /// **3R's Justification - Reliability:**
    /// - Testable unit: Can mock iterationEngine responses to verify iteration logic
    /// - Clear boundaries: Input (current state) → Output (IterationResult)
    /// - Isolated logic: Single iteration behavior independent of loop orchestration
    ///
    /// **3R's Justification - Readability:**
    /// - Descriptive name clearly indicates "one TRM iteration"
    /// - Encapsulates the core TRM algorithm: z(t+1), y(t+1) = f(z(t), y(t))
    /// - Returns named struct instead of tuple for clarity
    private func performSingleIteration(
        iterationNumber: Int,
        problem: String,
        context: String,
        currentPrediction: String,
        currentConfidence: Double,
        currentState: RefinementState
    ) async throws -> IterationResult {
        // Update latent state z(t+1) = f_z(problem, y(t), z(t))
        var updatedState = try await iterationEngine.updateLatentState(
            problem: problem,
            currentPrediction: currentPrediction,
            previousState: currentState,
            context: context
        )

        // Prune redundancies in latent state
        updatedState = stateTracker.pruneRedundancies(in: updatedState)

        // Refine prediction y(t+1) = f_y(problem, z(t+1), y(t))
        let refinedResult = try await iterationEngine.refinePrediction(
            problem: problem,
            latentState: updatedState,
            previousPrediction: currentPrediction,
            context: context
        )

        // Create iteration record for trajectory tracking
        let iteration = TRMIteration(
            id: UUID(),
            iterationNumber: iterationNumber,
            latentState: updatedState,
            prediction: refinedResult.prediction,
            confidence: refinedResult.confidence,
            improvementFromPrevious: refinedResult.confidence - currentConfidence,
            reasoning: refinedResult.reasoning,
            timestamp: Date()
        )

        return IterationResult(
            iteration: iteration,
            prediction: refinedResult.prediction,
            confidence: refinedResult.confidence,
            state: updatedState
        )
    }

    /// Check if refinement should halt
    ///
    /// **3R's Justification - Readability:**
    /// - Descriptive name: "shouldHalt" clearly indicates boolean decision
    /// - Consolidates two halting checks (evaluator + convergence)
    /// - Simplifies main loop condition
    private func shouldHalt(
        _ iteration: TRMIteration,
        _ confidenceTrajectory: [Double],
        _ confidenceThreshold: Double,
        _ maxIterations: Int
    ) -> Bool {
        // Use balanced policy for standalone TRM use case
        let policy = try! AdaptiveHaltingPolicy(
            minConvergenceProbability: 0.75,
            maxIterations: maxIterations,
            targetQuality: confidenceThreshold
        )

        let decision = haltingEvaluator.evaluate(
            trajectory: confidenceTrajectory,
            currentQuality: iteration.confidence,
            currentIteration: iteration.iterationNumber,
            policy: policy
        )

        return decision.shouldHalt
    }

    // MARK: - Private Methods

    /// Generate initial prediction (iteration 0)
    ///
    /// - Parameters:
    ///   - problem: Problem statement
    ///   - context: Additional context
    ///   - constraints: Constraints
    /// - Returns: Initial prediction with confidence
    private func generateInitialPrediction(
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> (prediction: String, confidence: Double) {
        let prompt = promptBuilder.buildInitialPredictionPrompt(
            problem: problem,
            context: context,
            constraints: constraints
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.3
        )

        let parser = TRMResponseParser()
        let parsed = parser.parseRefinedPrediction(response)

        return (prediction: parsed.prediction, confidence: parsed.confidence)
    }

    /// Build final refinement chain
    ///
    /// - Parameters:
    ///   - problem: Original problem
    ///   - initialPrediction: First prediction
    ///   - iterations: All iterations
    ///   - finalPrediction: Best prediction
    ///   - finalConfidence: Final confidence
    ///   - haltedEarly: Whether halted before max iterations
    ///   - convergenceTrajectory: Confidence trajectory
    /// - Returns: Complete refinement chain
    private func buildRefinementChain(
        problem: String,
        initialPrediction: String,
        iterations: [TRMIteration],
        finalPrediction: String,
        finalConfidence: Double,
        haltedEarly: Bool,
        convergenceTrajectory: [Double]
    ) -> TRMRefinementChain {
        return TRMRefinementChain(
            id: UUID(),
            problem: problem,
            initialPrediction: initialPrediction,
            iterations: iterations,
            finalPrediction: finalPrediction,
            finalConfidence: finalConfidence,
            haltedEarly: haltedEarly,
            totalIterations: iterations.count,
            convergenceTrajectory: convergenceTrajectory,
            timestamp: Date()
        )
    }
}
