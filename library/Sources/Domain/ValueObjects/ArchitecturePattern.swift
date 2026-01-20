import Foundation

/// Architecture patterns
/// Domain value object for architectural style classification
public enum ArchitecturePattern: String, Sendable, Codable {
    case mvc
    case mvvm
    case viper
    case clean
    case layered
    case microservices
}
