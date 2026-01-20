import Foundation

/// DTO for individual judge score database record
/// Single Responsibility: Data transfer for judge scores
struct JudgmentScoreRecord: Codable {
    let id: String
    let judgmentConsensusId: String
    let verificationQuestionId: String
    let judgeProvider: String
    let judgeModel: String
    let score: Double
    let confidence: Double
    let reasoning: String
    let weightedScore: Double
    let deviationFromConsensus: Double?
    let createdAt: String
}
