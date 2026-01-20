import Foundation
import Domain

/// Result of reasoning verification
/// Following Single Responsibility: Represents verification outcome
public struct VerificationResult: Sendable {
    public let isValid: Bool
    public let severity: VerificationSeverity
    public let issues: [String]
    public let contextGroundingScore: Double
    public let hallucinationRisk: Double

    public init(
        isValid: Bool,
        severity: VerificationSeverity,
        issues: [String],
        contextGroundingScore: Double,
        hallucinationRisk: Double
    ) {
        self.isValid = isValid
        self.severity = severity
        self.issues = issues
        self.contextGroundingScore = contextGroundingScore
        self.hallucinationRisk = hallucinationRisk
    }
}
