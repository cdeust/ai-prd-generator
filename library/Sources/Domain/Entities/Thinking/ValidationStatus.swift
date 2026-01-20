import Foundation

/// Validation status of assumption
/// Following Single Responsibility: Defines validation states only
public enum ValidationStatus: String, Sendable {
    case unverified
    case verified
    case invalidated
    case partial
    case needsReview
}
