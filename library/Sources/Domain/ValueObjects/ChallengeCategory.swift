import Foundation

/// Challenge categories
/// Domain value object for challenge classification
public enum ChallengeCategory: String, Sendable, Codable {
    case performance
    case security
    case scalability
    case integration
    case dataConsistency
    case userExperience
    case technical

    public var displayName: String {
        switch self {
        case .performance: return "Performance"
        case .security: return "Security"
        case .scalability: return "Scalability"
        case .integration: return "Integration"
        case .dataConsistency: return "Data Consistency"
        case .userExperience: return "User Experience"
        case .technical: return "Technical"
        }
    }
}
