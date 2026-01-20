import Foundation

/// Type of relationship between context nodes
/// Following Single Responsibility: Classifies context relationships
public enum ContextRelationship: String, Sendable {
    case supports
    case contradicts
    case refines
    case dependsOn
    case implements
    case references
    case derives
    case synthesizes
}
