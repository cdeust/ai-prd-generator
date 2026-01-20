import Foundation

/// Severity level of impact
/// Following Single Responsibility: Defines severity levels only
public enum ImpactSeverity: String, Sendable {
    case low
    case medium
    case high
    case critical
}
