import Foundation

/// DTO for simple answer update by question ID (when user responds)
struct AnswerByQuestionIdDTO: Codable {
    let userAnswer: String
    let answerTimestamp: Date

    enum CodingKeys: String, CodingKey {
        case userAnswer = "user_answer"
        case answerTimestamp = "answer_timestamp"
    }
}
