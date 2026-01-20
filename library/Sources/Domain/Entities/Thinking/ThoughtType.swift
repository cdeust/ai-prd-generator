import Foundation

/// Type of thought in reasoning process
/// Following Single Responsibility: Categorizes thought types only
public enum ThoughtType: String, Sendable, Codable {
    case observation
    case analysis
    case inference
    case conclusion
}
