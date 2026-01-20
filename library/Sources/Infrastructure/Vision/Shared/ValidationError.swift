import Foundation

/// Validation errors for vision analysis responses
public enum ValidationError: Error, Sendable {
    case noComponents
    case tooManyComponents(Int)
    case invalidPosition(index: Int)
    case invalidWidth(index: Int)
    case invalidHeight(index: Int)
    case missingComponentType(index: Int)
    case invalidComponentReference(String)
    case tooManyFlows(Int)
}

