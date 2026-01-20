import Foundation

/// Navigation strategies for decision tree traversal
/// Following Single Responsibility: Defines navigation strategies only
public enum NavigationStrategy: String, Sendable {
    case highestProbability
    case lowestRisk
    case balanced
    case aiRecommended
    case interactive
}
