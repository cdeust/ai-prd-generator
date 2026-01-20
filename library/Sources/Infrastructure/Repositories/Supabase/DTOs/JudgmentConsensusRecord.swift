import Foundation

/// DTO for judgment consensus database record
/// Single Responsibility: Data transfer for consensus results
struct JudgmentConsensusRecord: Codable {
    let id: String
    let verificationResultId: String
    let verificationQuestionId: String
    let consensusScore: Double
    let consensusConfidence: Double
    let agreementLevel: String
    let scoreVariance: Double?
    let createdAt: String
}
