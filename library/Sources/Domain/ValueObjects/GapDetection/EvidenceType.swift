import Foundation

/// Types of evidence sources
public enum EvidenceType: String, Codable, Sendable {
    /// Evidence from codebase search
    case codebase

    /// Evidence from mockup analysis
    case mockup

    /// Evidence from reasoning chain
    case reasoning

    /// Evidence from user-provided context
    case userContext

    /// Evidence from external documentation
    case documentation
}
