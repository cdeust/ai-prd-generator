import Foundation

/// Privacy level for AI generation
/// Following Single Responsibility Principle - represents privacy setting
public enum PrivacyLevel: String, Sendable, Codable {
    case minimal       // Minimal data sent to AI
    case standard      // Normal amount
    case detailed      // Include more context

    public var displayName: String {
        rawValue.capitalized
    }
}
