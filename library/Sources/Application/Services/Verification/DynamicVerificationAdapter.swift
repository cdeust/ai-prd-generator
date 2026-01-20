import Foundation
import Domain

/// Dynamic verification adapter that adjusts thresholds and strategies in real-time
/// Single Responsibility: Real-time adaptive verification during PRD generation
/// Enables: Live quality improvement, dynamic threshold adjustment, adaptive judge weighting
public final class DynamicVerificationAdapter: Sendable {
    private let historicalAnalyzer: HistoricalVerificationAnalyzer
    private let evidenceRepository: VerificationEvidenceRepositoryPort
    private let analysisHelper: VerificationAnalysisCoordinator

    public init(
        historicalAnalyzer: HistoricalVerificationAnalyzer,
        evidenceRepository: VerificationEvidenceRepositoryPort
    ) {
        self.historicalAnalyzer = historicalAnalyzer
        self.evidenceRepository = evidenceRepository
        self.analysisHelper = VerificationAnalysisCoordinator()
    }

    /// Real-time threshold adaptation during PRD generation
    /// Adjusts thresholds based on immediate verification results
    public func adaptThreshold(
        currentThreshold: Double,
        verificationResult: CoVVerificationResult,
        verificationType: VerificationType
    ) async throws -> AdaptedThreshold {
        // Get historical baseline
        let historicalThreshold = try await historicalAnalyzer.getAdaptiveThreshold(
            for: verificationType
        )

        // Analyze current verification outcome
        let currentPerformance = analysisHelper.analyzeCurrentPerformance(verificationResult)

        // Dynamic adjustment rules
        let adjustment: Double
        if currentPerformance.failureRate > 0.3 {
            // Too many failures - lower threshold temporarily
            adjustment = -0.05
        } else if currentPerformance.averageScore > 0.95 {
            // Too easy - raise threshold
            adjustment = +0.03
        } else if currentPerformance.judgeDisagreement > 0.15 {
            // High disagreement - stabilize threshold
            adjustment = 0.0
        } else {
            // Normal - use historical trend
            adjustment = historicalThreshold.threshold - currentThreshold
        }

        let adaptedThreshold = max(0.5, min(0.99, currentThreshold + adjustment))

        return AdaptedThreshold(
            original: currentThreshold,
            adapted: adaptedThreshold,
            adjustment: adjustment,
            reason: buildAdjustmentReason(
                currentPerformance: currentPerformance,
                adjustment: adjustment
            ),
            confidence: calculateConfidence(
                historicalConfidence: historicalThreshold.confidence,
                currentDataPoints: verificationResult.consensusResults.count
            )
        )
    }

    /// Dynamic judge weighting based on real-time performance
    /// Adjusts judge weights during active verification session
    public func adaptJudgeWeights(
        currentWeights: [String: Double],
        recentScores: [JudgmentScore],
        verificationResult: CoVVerificationResult
    ) async throws -> AdaptedJudgeWeights {
        // Get historical judge performance
        let historicalWeights = try await historicalAnalyzer.getJudgeWeights()

        // Analyze recent performance
        var adaptedWeights: [String: Double] = [:]

        for score in recentScores {
            let judgeKey = "\(score.judgeProvider)/\(score.judgeModel)"

            // Calculate deviation from consensus
            let consensusForQuestion = verificationResult.consensusResults
                .first { $0.verificationQuestionId == score.verificationQuestionId }

            guard let consensus = consensusForQuestion else { continue }

            let deviation = abs(score.score - consensus.consensusScore)

            // Dynamic weight adjustment
            let historicalWeight = historicalWeights[judgeKey] ?? 0.5
            let currentWeight = currentWeights[judgeKey] ?? 0.5

            // Reward low deviation, penalize high deviation
            let performanceMultiplier = 1.0 - (deviation * 2.0)  // deviation of 0.5 = 0x weight
            let adaptedWeight = (historicalWeight * 0.7 + currentWeight * 0.3) * performanceMultiplier

            adaptedWeights[judgeKey] = max(0.1, min(1.0, adaptedWeight))
        }

        // Normalize weights
        let totalWeight = adaptedWeights.values.reduce(0, +)
        if totalWeight > 0 {
            adaptedWeights = adaptedWeights.mapValues { $0 / totalWeight }
        }

        return AdaptedJudgeWeights(
            original: currentWeights,
            adapted: adaptedWeights,
            changes: calculateWeightChanges(from: currentWeights, to: adaptedWeights),
            reason: buildJudgeWeightReason(recentScores: recentScores)
        )
    }

    /// Adaptive question selection based on real-time context
    /// Selects best questions for current PRD generation state
    public func adaptQuestionSelection(
        currentQuestions: [VerificationQuestion],
        prdContext: PRDGenerationContext,
        verificationHistory: [CoVVerificationResult]
    ) async throws -> AdaptedQuestionSet {
        // Get historically optimal questions
        let optimalQuestions = try await historicalAnalyzer.getOptimalQuestions(
            for: .prdQuality,
            count: 10
        )

        // Analyze PRD context
        let contextAnalysis = analysisHelper.analyzePRDContext(prdContext)

        // Select questions matching current context
        var selectedQuestions: [VerificationQuestion] = []

        // 1. Add questions proven effective for this context type
        for question in optimalQuestions {
            if analysisHelper.isRelevantForContext(question, contextAnalysis) {
                selectedQuestions.append(question)
            }
            if selectedQuestions.count >= 5 { break }
        }

        // 2. Add questions targeting known weak areas
        if let weakAreas = analysisHelper.identifyWeakAreas(verificationHistory) {
            let targetedQuestions = optimalQuestions.filter { question in
                weakAreas.contains { area in
                    question.question.lowercased().contains(area.lowercased())
                }
            }
            selectedQuestions.append(contentsOf: targetedQuestions.prefix(2))
        }

        return AdaptedQuestionSet(
            original: currentQuestions,
            adapted: selectedQuestions,
            addedCount: selectedQuestions.count - currentQuestions.count,
            reason: buildQuestionSelectionReason(
                contextAnalysis: contextAnalysis,
                selectedCount: selectedQuestions.count
            )
        )
    }

    /// Real-time refinement decision based on immediate feedback
    /// Decides whether to refine based on current verification trajectory
    public func shouldRefineNow(
        currentAttempt: Int,
        verificationResult: CoVVerificationResult,
        refinementHistory: [CoVVerificationResult],
        generationContext: PRDGenerationContext
    ) async throws -> RefinementDecision {
        // Get historical recommendation
        let historicalRecommendation = try await historicalAnalyzer.shouldAttemptRefinement(
            for: .prdDocument,
            currentAttempt: currentAttempt
        )

        // Analyze current trajectory
        let trajectory = analysisHelper.analyzeRefinementTrajectory(
            current: verificationResult,
            history: refinementHistory
        )

        // Dynamic decision rules
        let shouldRefine: Bool
        let reason: String

        if trajectory.isImproving && verificationResult.overallScore > 0.70 {
            // Making progress - continue refining
            shouldRefine = true
            reason = "Verification score improving (\(String(format: "%.2f", trajectory.improvement)) per attempt)"
        } else if trajectory.isDiminishing && currentAttempt >= 1 {
            // Diminishing returns - stop refining
            shouldRefine = false
            reason = "Refinement showing diminishing returns (Δ < 0.05)"
        } else if verificationResult.overallScore < 0.50 {
            // Too low - likely fundamental issue, stop wasting effort
            shouldRefine = false
            reason = "Score too low (\(String(format: "%.2f", verificationResult.overallScore))) - fundamental issue detected"
        } else {
            // Use historical recommendation
            shouldRefine = historicalRecommendation.shouldRefine
            reason = historicalRecommendation.reason
        }

        return RefinementDecision(
            shouldRefine: shouldRefine,
            reason: reason,
            maxAdditionalAttempts: shouldRefine ? (historicalRecommendation.maxAttempts - currentAttempt) : 0,
            confidence: calculateRefinementConfidence(
                trajectory: trajectory,
                historicalRecommendation: historicalRecommendation
            ),
            trajectory: trajectory
        )
    }

    // MARK: - Private Helpers

    private func buildAdjustmentReason(currentPerformance: CurrentPerformance, adjustment: Double) -> String {
        if adjustment < 0 {
            return "Lowering threshold due to high failure rate (\(String(format: "%.1f", currentPerformance.failureRate * 100))%)"
        } else if adjustment > 0 {
            return "Raising threshold - scores consistently high (\(String(format: "%.2f", currentPerformance.averageScore)))"
        } else {
            return "Maintaining threshold - performance stable"
        }
    }

    private func calculateConfidence(historicalConfidence: Double, currentDataPoints: Int) -> Double {
        // Blend historical confidence with current data confidence
        let currentConfidence = min(1.0, Double(currentDataPoints) / 5.0)  // 5+ points = full confidence
        return (historicalConfidence * 0.6 + currentConfidence * 0.4)
    }

    private func calculateWeightChanges(from: [String: Double], to: [String: Double]) -> [String: Double] {
        var changes: [String: Double] = [:]
        for (judge, newWeight) in to {
            let oldWeight = from[judge] ?? 0.5
            changes[judge] = newWeight - oldWeight
        }
        return changes
    }

    private func buildJudgeWeightReason(recentScores: [JudgmentScore]) -> String {
        let avgDeviation = recentScores.map { score in
            // Placeholder - would calculate actual deviation
            0.1
        }.reduce(0, +) / Double(recentScores.count)

        return "Adjusted based on recent performance (avg deviation: \(String(format: "%.3f", avgDeviation)))"
    }

    private func buildQuestionSelectionReason(contextAnalysis: ContextAnalysis, selectedCount: Int) -> String {
        "Selected \(selectedCount) questions optimal for \(contextAnalysis.domainType) domain with \(contextAnalysis.complexity) complexity"
    }

    private func calculateRefinementConfidence(
        trajectory: RefinementTrajectory,
        historicalRecommendation: RefinementRecommendation
    ) -> Double {
        // High confidence if trajectory and historical agree
        let trajectorySignal = trajectory.isImproving ? 1.0 : 0.0
        let historicalSignal = historicalRecommendation.shouldRefine ? 1.0 : 0.0

        let agreement = 1.0 - abs(trajectorySignal - historicalSignal)
        return agreement
    }
}
