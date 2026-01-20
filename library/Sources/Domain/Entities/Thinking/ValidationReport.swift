import Foundation

/// Validation report for assumptions
/// Following Single Responsibility: Generates validation report only
public struct ValidationReport: Sendable {
    public let id: UUID
    public let timestamp: Date
    public let totalAssumptions: Int
    public let validated: Int
    public let valid: Int
    public let invalid: Int
    public let results: [ValidationResult]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        totalAssumptions: Int,
        validated: Int,
        valid: Int,
        invalid: Int,
        results: [ValidationResult]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.totalAssumptions = totalAssumptions
        self.validated = validated
        self.valid = valid
        self.invalid = invalid
        self.results = results
    }

    public var summary: String {
        buildSummary()
    }

    private func buildSummary() -> String {
        let validPercentage = calculateValidPercentage()
        let unverified = totalAssumptions - validated

        return formatSummary(
            validPercentage: validPercentage,
            unverified: unverified
        )
    }

    private func calculateValidPercentage() -> Float {
        guard validated > 0 else { return 0 }
        return Float(valid) / Float(validated) * 100
    }

    private func formatSummary(
        validPercentage: Float,
        unverified: Int
    ) -> String {
        """
        Validation Report:
        - Total Assumptions: \(totalAssumptions)
        - Validated: \(validated)
        - Valid: \(valid) (\(String(format: "%.1f%%", validPercentage)))
        - Invalid: \(invalid)
        - Unverified: \(unverified)
        """
    }
}
