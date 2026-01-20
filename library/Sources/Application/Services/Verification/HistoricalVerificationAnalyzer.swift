import Foundation
import Domain

/// Analyzes historical verification data for meta-learning
/// Single Responsibility: Extract insights from verification history
/// Enables exponential accuracy improvement through pattern recognition
public final class HistoricalVerificationAnalyzer: Sendable {
    private let repository: VerificationEvidenceRepositoryPort

    public init(repository: VerificationEvidenceRepositoryPort) {
        self.repository = repository
    }

    /// Get adaptive verification threshold based on historical performance
    /// Meta-CoV: Learn from past verifications to set better thresholds
    public func getAdaptiveThreshold(
        for verificationType: VerificationType,
        lookbackDays: Int = 30
    ) async throws -> AdaptiveThreshold {
        let since = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: Date()) ?? Date()
        let stats = try await repository.getVerificationStatistics(for: verificationType, since: since)

        // If we have enough history, use data-driven threshold
        guard stats.totalVerifications >= 10 else {
            // Not enough data - use default conservative threshold
            return AdaptiveThreshold(
                threshold: VerificationThresholds.questionVerification,
                confidence: 0.3,
                source: .default,
                sampleSize: stats.totalVerifications
            )
        }

        // Calculate adaptive threshold from historical data
        // Use mean - 0.5 * stddev for conservative but data-driven threshold
        let threshold = stats.recommendedThreshold

        return AdaptiveThreshold(
            threshold: threshold,
            confidence: calculateConfidence(sampleSize: stats.totalVerifications),
            source: .historicalData,
            sampleSize: stats.totalVerifications
        )
    }

    /// Get optimal verification questions based on effectiveness
    /// Meta-CoV: Learn which questions produce best consensus
    public func getOptimalQuestions(
        for verificationType: VerificationType,
        count: Int = 5
    ) async throws -> [VerificationQuestion] {
        return try await repository.getOptimalQuestions(for: verificationType, limit: count)
    }

    /// Analyze which judges are most reliable for this verification type
    /// Meta-CoV: Weight judge scores by historical reliability
    public func getJudgeWeights() async throws -> [String: Double] {
        let performance = try await repository.getJudgePerformance(provider: nil, model: nil)

        var weights: [String: Double] = [:]
        for metrics in performance where metrics.isReliable {
            let judgeKey = "\(metrics.judgeProvider)/\(metrics.judgeModel)"
            // Weight = reliability score (0-1)
            weights[judgeKey] = metrics.reliabilityScore
        }

        // Normalize weights to sum to 1.0
        let totalWeight = weights.values.reduce(0, +)
        if totalWeight > 0 {
            weights = weights.mapValues { $0 / totalWeight }
        }

        return weights
    }

    /// Get judge weights with bootstrap for new providers
    /// Returns default weight (1.0) for judges without historical data
    /// Enables new providers (OpenRouter, Bedrock) to participate in consensus
    /// Meta-CoV: Graceful degradation for judges with no history
    public func getJudgeWeightsWithBootstrap() async throws -> [String: Double] {
        let historicalWeights = try await getJudgeWeights()

        // Bootstrap new providers with default weight if no history
        var weights = historicalWeights

        // Check for OpenRouter
        if !weights.keys.contains(where: { $0.contains("OpenRouter") }) {
            weights["OpenRouter"] = 1.0  // Default weight
        }

        // Check for Bedrock
        if !weights.keys.contains(where: { $0.contains("Bedrock") }) {
            weights["AWS Bedrock"] = 1.0  // Default weight
        }

        // Normalize weights to sum to 1.0
        let totalWeight = weights.values.reduce(0, +)
        if totalWeight > 0 {
            weights = weights.mapValues { $0 / totalWeight }
        }

        return weights
    }

    /// Determine if refinement is worth attempting
    /// Meta-CoV: Learn from past refinement effectiveness
    public func shouldAttemptRefinement(
        for entityType: VerificationEntityType,
        currentAttempt: Int
    ) async throws -> RefinementRecommendation {
        let effectiveness = try await repository.getRefinementEffectiveness(for: entityType)

        // Check if refinement is generally effective
        guard effectiveness.refinementIsEffective else {
            return RefinementRecommendation(
                shouldRefine: false,
                reason: "Historical data shows refinement rarely improves scores (success rate: \(effectiveness.successRate))",
                maxAttempts: 0
            )
        }

        // Check if this specific attempt number is effective
        if let attemptMetrics = effectiveness.refinementsByAttempt[currentAttempt] {
            let isWorthwhile = attemptMetrics.successRate > 0.6 && attemptMetrics.averageScore > 0.7

            return RefinementRecommendation(
                shouldRefine: isWorthwhile,
                reason: isWorthwhile
                    ? "Attempt \(currentAttempt) historically successful (\(attemptMetrics.successRate) success rate)"
                    : "Attempt \(currentAttempt) historically ineffective (\(attemptMetrics.successRate) success rate)",
                maxAttempts: findMaxEffectiveAttempts(effectiveness.refinementsByAttempt)
            )
        }

        // No data for this attempt - use general effectiveness
        return RefinementRecommendation(
            shouldRefine: currentAttempt < 2, // Conservative: max 2 attempts
            reason: "No historical data for attempt \(currentAttempt), using conservative limit",
            maxAttempts: 2
        )
    }

    /// Analyze verification trends to detect degradation
    /// Meta-CoV: Monitor if verification quality is declining
    public func detectQualityDegradation(
        for verificationType: VerificationType
    ) async throws -> QualityTrend {
        let recentStats = try await repository.getVerificationStatistics(
            for: verificationType,
            since: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        )

        let historicalStats = try await repository.getVerificationStatistics(
            for: verificationType,
            since: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        )

        guard recentStats.totalVerifications >= 5 && historicalStats.totalVerifications >= 10 else {
            return QualityTrend.insufficient_data
        }

        let scoreDelta = recentStats.averageScore - historicalStats.averageScore
        let confidenceDelta = recentStats.averageConfidence - historicalStats.averageConfidence

        // Significant degradation if score drops > 0.1 or confidence drops > 0.15
        if scoreDelta < -0.1 || confidenceDelta < -0.15 {
            return .degrading(scoreDelta: scoreDelta, confidenceDelta: confidenceDelta)
        }

        // Significant improvement if score rises > 0.1 or confidence rises > 0.15
        if scoreDelta > 0.1 || confidenceDelta > 0.15 {
            return .improving(scoreDelta: scoreDelta, confidenceDelta: confidenceDelta)
        }

        return .stable
    }

    // MARK: - Private Helpers

    private func calculateConfidence(sampleSize: Int) -> Double {
        // Confidence grows with sample size, plateaus at 100+ samples
        // Formula: 1 - exp(-sampleSize/50)
        return min(1.0, 1.0 - exp(-Double(sampleSize) / 50.0))
    }

    private func findMaxEffectiveAttempts(_ metrics: [Int: RefinementAttemptMetrics]) -> Int {
        guard !metrics.isEmpty else { return 2 }

        // Find highest attempt number where success rate > 0.6
        let effective = metrics.filter { $0.value.successRate > 0.6 }
        return effective.keys.max() ?? 2
    }
}
