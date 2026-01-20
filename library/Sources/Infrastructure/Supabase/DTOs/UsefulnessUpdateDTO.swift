import Foundation

/// DTO for usefulness update in RAG context trace
struct UsefulnessUpdateDTO: Codable {
    let userFeedback: Bool
    let actualUsefulness: String

    enum CodingKeys: String, CodingKey {
        case userFeedback = "user_feedback"
        case actualUsefulness = "actual_usefulness"
    }
}
