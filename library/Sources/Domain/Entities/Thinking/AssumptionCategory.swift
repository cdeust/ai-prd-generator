import Foundation

/// Category of tracked assumption
/// Following Single Responsibility: Categorizes assumptions only
public enum AssumptionCategory: String, Sendable {
    case technical
    case business
    case user
    case performance
    case security
    case data
}
