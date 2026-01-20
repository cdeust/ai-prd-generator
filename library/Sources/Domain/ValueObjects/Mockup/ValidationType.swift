import Foundation

/// Type of validation rule for data fields
public enum ValidationType: String, Sendable, Codable {
    case required = "Required"
    case minLength = "Minimum Length"
    case maxLength = "Maximum Length"
    case pattern = "Pattern"
    case email = "Email Format"
    case url = "URL Format"
    case phone = "Phone Format"
    case numeric = "Numeric"
    case alphanumeric = "Alphanumeric"
    case minValue = "Minimum Value"
    case maxValue = "Maximum Value"
    case range = "Range"
    case custom = "Custom"
}
