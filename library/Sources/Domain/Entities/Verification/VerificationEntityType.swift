import Foundation

/// Type of entity being verified
public enum VerificationEntityType: String, Sendable, Codable {
    case prdDocument = "prd_document"
    case clarificationSession = "clarification_session"
    case prdSection = "prd_section"
}
