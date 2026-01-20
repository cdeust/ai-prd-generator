import Foundation
import Domain

/// Assesses reliability of verified thought chains
/// Following Single Responsibility: Reliability assessment only
struct ReliabilityAssessor {
    /// Assess reliability of a verified reasoning chain
    func assess(
        verifiedChain: VerifiedThoughtChain,
        retrievalMetadata: RetrievalMetadata?
    ) -> ReliabilityAssessment {
        var score = verifiedChain.confidence
        var issues: [String] = []

        // Factor 1: Verification status
        if !verifiedChain.wasVerified {
            score *= 0.7
            issues.append("Chain was not verified")
        }

        // Factor 2: Number of corrections needed
        let correctionsCount = verifiedChain.hops.filter(\.wasCorrected).count
        let correctionPenalty = Double(correctionsCount) * 0.1
        score -= correctionPenalty

        if correctionsCount > 0 {
            issues.append("\(correctionsCount) reasoning steps needed correction")
        }

        // Factor 3: Assumption quality
        let highRiskAssumptions = verifiedChain.assumptions.filter {
            $0.requiresValidation && $0.confidence < 0.5
        }

        if !highRiskAssumptions.isEmpty {
            score *= 0.85
            issues.append("\(highRiskAssumptions.count) high-risk assumptions")
        }

        // Factor 4: Context grounding (RAG quality)
        if let metadata = retrievalMetadata {
            let retrievalQuality = Double(metadata.finalSelected) /
                Double(max(metadata.afterReranking, 1))

            if retrievalQuality < 0.5 {
                score *= 0.9
                issues.append("Low retrieval quality")
            }
        }

        // Factor 5: Reasoning depth
        if verifiedChain.hops.count < 2 {
            score *= 0.9
            issues.append("Insufficient reasoning depth")
        }

        return ReliabilityAssessment(
            score: max(0.0, min(1.0, score)),
            issues: issues
        )
    }
}
