import Foundation

/// Generic category type with type parameter T
///
/// Professional generic design - supports any type for categorization.
/// No hardcoded values, fully extensible through type parameter.
public struct QuestionCategory<T: Hashable & Codable & Sendable>: Sendable, Codable, Hashable {
    public let value: T

    public init(_ value: T) {
        self.value = value
    }
}
