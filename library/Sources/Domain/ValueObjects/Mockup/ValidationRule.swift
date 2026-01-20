import Foundation

/// Validation rule for a data field
public struct ValidationRule: Sendable, Codable, Equatable {
    /// Type of validation
    public let type: ValidationType

    /// Parameter for the validation (e.g., "10" for minLength)
    public let parameter: String?

    /// Error message when validation fails
    public let errorMessage: String?

    public init(
        type: ValidationType,
        parameter: String? = nil,
        errorMessage: String? = nil
    ) {
        self.type = type
        self.parameter = parameter
        self.errorMessage = errorMessage
    }
}
