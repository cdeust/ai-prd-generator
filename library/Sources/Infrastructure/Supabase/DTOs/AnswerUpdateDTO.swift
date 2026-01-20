import Foundation

/// DTO for answer update in clarification trace with full impact analysis
struct AnswerUpdateDTO: Codable {
    let userAnswer: String
    let answerTimestamp: Date
    let impactOnPrd: String?
    let influencedSections: [String]

    enum CodingKeys: String, CodingKey {
        case userAnswer = "user_answer"
        case answerTimestamp = "answer_timestamp"
        case impactOnPrd = "impact_on_prd"
        case influencedSections = "influenced_sections"
    }
}
