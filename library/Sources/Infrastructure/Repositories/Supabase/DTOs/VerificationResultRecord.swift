import Foundation

/// DTO for verification result database record
/// Single Responsibility: Data transfer for verification results
struct VerificationResultRecord: Codable {
    let id: String
    let entityType: String
    let entityId: String
    let originalResponse: String
    let overallScore: Double
    let overallConfidence: Double
    let verified: Bool
    let verificationType: String
    let refinementAttempt: Int
    let recommendationsJson: String?
    let createdAt: String
    let prdDocumentId: String?
    let clarificationSessionId: String?
}
