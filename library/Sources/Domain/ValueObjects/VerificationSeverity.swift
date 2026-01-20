import Foundation

/// Severity level of verification issues
/// Following Single Responsibility: Represents severity classification
public enum VerificationSeverity: Comparable, Sendable {
    case valid
    case minor
    case major
    case critical
}
