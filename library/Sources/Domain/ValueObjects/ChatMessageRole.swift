import Foundation

/// Chat message role
/// Following Single Responsibility Principle - represents message sender role
public enum ChatMessageRole: String, Codable, Sendable {
    case system
    case user
    case assistant
}
