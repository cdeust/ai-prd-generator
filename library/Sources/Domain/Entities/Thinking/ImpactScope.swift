import Foundation

/// Scope of impact from assumption
/// Following Single Responsibility: Defines impact scope only
public enum ImpactScope: String, Sendable {
    case local
    case module
    case system
    case critical
}
