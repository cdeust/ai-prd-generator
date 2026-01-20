import Foundation

/// PRD document privacy level
/// Maps to prd_privacy_level enum in database
/// Following Single Responsibility Principle - represents document visibility
public enum PRDPrivacyLevel: String, Codable, Sendable {
    case `public`    // Visible to everyone
    case unlisted    // Accessible via link only
    case `private`   // Owner only

    public var displayName: String {
        switch self {
        case .public:
            return "Public"
        case .unlisted:
            return "Unlisted"
        case .private:
            return "Private"
        }
    }

    public var description: String {
        switch self {
        case .public:
            return "Anyone can view this PRD"
        case .unlisted:
            return "Only people with the link can view"
        case .private:
            return "Only you can view this PRD"
        }
    }
}
