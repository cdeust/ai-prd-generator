import Foundation

/// DTO for user feedback update in performance metrics
struct UserFeedbackUpdateDTO: Codable {
    let userSatisfactionScore: Double
    let userWouldRecommend: Bool
    let userFeedbackText: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userSatisfactionScore = "user_satisfaction_score"
        case userWouldRecommend = "user_would_recommend"
        case userFeedbackText = "user_feedback_text"
        case updatedAt = "updated_at"
    }
}
