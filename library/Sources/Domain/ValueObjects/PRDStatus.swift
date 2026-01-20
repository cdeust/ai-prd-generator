import Foundation

/// PRD document status
/// Maps to prd_status enum in database
public enum PRDStatus: String, Codable, Sendable {
    case draft
    case inReview = "in_review"
    case approved
    case archived
}
