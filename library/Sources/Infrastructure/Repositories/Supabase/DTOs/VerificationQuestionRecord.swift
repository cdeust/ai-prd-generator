import Foundation

/// DTO for verification question database record
/// Single Responsibility: Data transfer for verification questions
struct VerificationQuestionRecord: Codable {
    let id: String
    let questionText: String
    let questionType: String
    let importanceWeight: Double?
    let createdAt: String
    let timesUsed: Int?
    let averageConsensusScore: Double?
    let averageJudgeAgreement: Double?
}
