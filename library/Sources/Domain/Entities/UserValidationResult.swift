import Foundation

/// User validation result
/// Domain value object for validation feedback
public struct UserValidationResult: Sendable {
    public let isValid: Bool
    public let message: String
    public let details: [String]

    public init(isValid: Bool, message: String, details: [String] = []) {
        self.isValid = isValid
        self.message = message
        self.details = details
    }
}
