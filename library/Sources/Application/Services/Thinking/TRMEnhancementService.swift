import Foundation
import Domain

/// TRM-powered enhancement service for reasoning strategies
///
/// Applies recursive refinement with intelligent halting to any strategy
/// that produces refinable results.
///
/// **Features:**
/// - Convergence detection
/// - Oscillation prevention
/// - Diminishing returns detection
/// - Confidence calibration
///
/// **Usage:**
/// ```swift
/// let service = TRMEnhancementService(
///     aiProvider: provider,
///     haltingEvaluator: evaluator
/// )
///
/// let enhanced = try await service.enhance(
///     baseResult: initialResult,
///     problem: problem,
///     context: context,
///     refiner: { prev, prob, ctx in
///         try await refineResult(prev, prob, ctx)
///     },
///     config: TRMConfig(maxIterations: 5)
/// )
/// ```
public struct TRMEnhancementService: Sendable {
    private let aiProvider: AIProviderPort
    private let haltingEvaluator: TRMHaltingEvaluator

    public init(
        aiProvider: AIProviderPort,
        haltingEvaluator: TRMHaltingEvaluator = TRMHaltingEvaluator()
    ) {
        self.aiProvider = aiProvider
        self.haltingEvaluator = haltingEvaluator
    }

    // MARK: - Public Methods

    /// Enhance base result with TRM recursive refinement
    public func enhance<T: RefinableResult>(
        baseResult: T,
        problem: String,
        context: String,
        refiner: Refiner<T>,
        config: TRMConfig
    ) async throws -> EnhancedResult<T> {
        var currentResult = baseResult
        var confidenceTrajectory = [baseResult.confidence]
        let initialConfidence = baseResult.confidence

        for iteration in 1...config.policy.maxIterations {
            let decision = haltingEvaluator.evaluate(
                trajectory: confidenceTrajectory,
                currentQuality: currentResult.confidence,
                currentIteration: iteration,
                policy: config.policy
            )

            if decision.shouldHalt {
                let evidence = ConvergenceEvidence(trajectory: confidenceTrajectory)
                return buildEnhancedResult(
                    result: currentResult,
                    iterations: iteration - 1,
                    trajectory: confidenceTrajectory,
                    initialConfidence: initialConfidence,
                    evidence: evidence,
                    config: config
                )
            }

            currentResult = try await refiner(
                currentResult,
                problem,
                context
            )
            confidenceTrajectory.append(currentResult.confidence)
        }

        let evidence = ConvergenceEvidence(trajectory: confidenceTrajectory)
        return buildEnhancedResult(
            result: currentResult,
            iterations: config.policy.maxIterations,
            trajectory: confidenceTrajectory,
            initialConfidence: initialConfidence,
            evidence: evidence,
            config: config
        )
    }

    // MARK: - Private Methods

    private func createIteration<T: RefinableResult>(
        number: Int,
        result: T
    ) -> TRMIteration {
        TRMIteration(
            id: UUID(),
            iterationNumber: number,
            latentState: .initial(),
            prediction: result.conclusion,
            confidence: result.confidence,
            improvementFromPrevious: 0.0,
            reasoning: "",
            timestamp: Date()
        )
    }

    private func buildEnhancedResult<T: RefinableResult>(
        result: T,
        iterations: Int,
        trajectory: [Double],
        initialConfidence: Double,
        evidence: ConvergenceEvidence,
        config: TRMConfig
    ) -> EnhancedResult<T> {
        return EnhancedResult(
            result: result,
            iterationsPerformed: iterations,
            converged: evidence.showsStrongConvergence,
            haltedOnOscillation: evidence.showsOscillation,
            haltedOnDiminishingReturns: evidence.showsDiminishingReturns,
            confidenceImprovement: result.confidence - initialConfidence
        )
    }
}
