import Foundation

/// Technical complexity level for prompt generation
public enum ComplexityLevel: String, Sendable {
    case simple     // Basic applications, MVPs
    case medium     // Standard production applications
    case complex    // Enterprise, distributed systems
    case advanced   // Research, cutting-edge technology
}
