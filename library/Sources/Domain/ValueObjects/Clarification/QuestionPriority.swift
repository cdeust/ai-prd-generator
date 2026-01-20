import Foundation

/// Generic priority type with type parameter T
///
/// Professional generic design - T must be Comparable for sorting.
/// No hardcoded priority levels, fully extensible.
public struct QuestionPriority<T: Comparable & Codable & Sendable & Hashable>: Sendable, Codable, Hashable, Comparable {
    public let value: T

    public init(_ value: T) {
        self.value = value
    }

    public static func < (lhs: QuestionPriority<T>, rhs: QuestionPriority<T>) -> Bool {
        lhs.value < rhs.value
    }
}
