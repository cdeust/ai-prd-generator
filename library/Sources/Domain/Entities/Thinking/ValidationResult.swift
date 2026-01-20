import Foundation

/// Result from validation logic
/// Following Single Responsibility: Represents validation outcome only
public struct ValidationResult: Identifiable, Sendable {
    public let id: UUID
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]

    public init(
        id: UUID = UUID(),
        isValid: Bool,
        errors: [String] = [],
        warnings: [String] = []
    ) {
        self.id = id
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}
