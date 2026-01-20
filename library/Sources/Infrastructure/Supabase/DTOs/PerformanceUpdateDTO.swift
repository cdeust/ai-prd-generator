import Foundation

/// DTO for performance update in strategy decision
struct PerformanceUpdateDTO: Codable {
    let actualPerformance: [String: Double]?
    let wasEffective: Bool
    let lessonsLearned: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case actualPerformance = "actual_performance"
        case wasEffective = "was_effective"
        case lessonsLearned = "lessons_learned"
        case updatedAt = "updated_at"
    }
}
