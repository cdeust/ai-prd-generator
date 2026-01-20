import Foundation

/// Consensus from multiple reasoning paths
struct ConsensusResult {
    let answer: String
    let supportingReasoning: String
    let agreement: Double
    let confidence: Double
}
