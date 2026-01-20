import Foundation

/// DTO for effectiveness update in clarification trace
struct EffectivenessUpdateDTO: Codable {
    let wasHelpful: Bool
    let improvedQuality: Bool
    let shouldAskAgainForSimilar: Bool

    enum CodingKeys: String, CodingKey {
        case wasHelpful = "was_helpful"
        case improvedQuality = "improved_quality"
        case shouldAskAgainForSimilar = "should_ask_again_for_similar"
    }
}
