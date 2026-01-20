import Foundation
import Domain

/// Coordinator for verification analysis operations
/// Single Responsibility: Analyze verification data for decision-making
internal struct VerificationAnalysisCoordinator {

    /// Analyze current verification performance metrics
    internal func analyzeCurrentPerformance(
        _ result: CoVVerificationResult
    ) -> CurrentPerformance {
        let avgScore = result.consensusResults.map(\.consensusScore).reduce(0, +) / Double(result.consensusResults.count)
        let failureRate = Double(result.consensusResults.filter { $0.consensusScore < 0.6 }.count) / Double(result.consensusResults.count)

        let scoreVariances = result.consensusResults.map(\.scoreVariance)
        let avgDisagreement = scoreVariances.reduce(0, +) / Double(scoreVariances.count)

        return CurrentPerformance(
            averageScore: avgScore,
            failureRate: failureRate,
            judgeDisagreement: avgDisagreement
        )
    }

    /// Analyze PRD generation context for adaptive decisions
    internal func analyzePRDContext(_ context: PRDGenerationContext) -> ContextAnalysis {
        ContextAnalysis(
            complexity: context.sections.count > 5 ? .high : .medium,
            domainType: inferDomainType(from: context.projectName),
            requiresClarification: context.hasAmbiguity
        )
    }

    /// Analyze refinement trajectory to detect improvement patterns
    internal func analyzeRefinementTrajectory(
        current: CoVVerificationResult,
        history: [CoVVerificationResult]
    ) -> RefinementTrajectory {
        guard !history.isEmpty else {
            return RefinementTrajectory(isImproving: false, isDiminishing: false, improvement: 0.0)
        }

        let scores = history.map(\.overallScore) + [current.overallScore]

        // Calculate improvement per attempt
        var improvements: [Double] = []
        for i in 1..<scores.count {
            improvements.append(scores[i] - scores[i-1])
        }

        let avgImprovement = improvements.reduce(0, +) / Double(improvements.count)
        let isImproving = avgImprovement > 0.02  // Improving if avg gain > 2%
        let isDiminishing = improvements.count >= 2 &&
                           improvements.last! < improvements[improvements.count - 2] / 2.0

        return RefinementTrajectory(
            isImproving: isImproving,
            isDiminishing: isDiminishing,
            improvement: avgImprovement
        )
    }

    /// Identify consistently weak verification categories
    internal func identifyWeakAreas(_ history: [CoVVerificationResult]) -> [String]? {
        guard !history.isEmpty else { return nil }

        // Find consistently low-scoring question categories
        var categoryScores: [String: [Double]] = [:]

        for result in history {
            for consensus in result.consensusResults {
                // Find the question for this consensus
                let question = result.verificationQuestions.first {
                    $0.id == consensus.verificationQuestionId
                }

                if let question = question {
                    let category = question.category.rawValue
                    categoryScores[category, default: []].append(consensus.consensusScore)
                }
            }
        }

        // Identify categories with avg score < 0.7
        let weakCategories = categoryScores
            .filter { $0.value.reduce(0, +) / Double($0.value.count) < 0.7 }
            .map(\.key)

        return weakCategories.isEmpty ? nil : weakCategories
    }

    /// Check if question is relevant for context
    internal func isRelevantForContext(
        _ question: VerificationQuestion,
        _ context: ContextAnalysis
    ) -> Bool {
        // Match question type to context needs
        switch context.complexity {
        case .high:
            return question.category == .completeness || question.category == .consistency
        case .medium:
            return question.category == .factualAccuracy || question.category == .relevance
        case .low:
            return question.category == .clarity
        }
    }

    // MARK: - Private Helpers

    private func inferDomainType(from projectName: String) -> String {
        // Simple heuristic - could be ML-based in future
        let name = projectName.lowercased()
        if name.contains("api") || name.contains("backend") {
            return "backend"
        } else if name.contains("ui") || name.contains("frontend") {
            return "frontend"
        } else if name.contains("mobile") || name.contains("ios") || name.contains("android") {
            return "mobile"
        } else {
            return "general"
        }
    }
}
