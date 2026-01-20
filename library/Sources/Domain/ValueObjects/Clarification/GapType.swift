import Foundation

/// Generic gap type with type parameter T
///
/// Professional generic design - supports any type for gap identification.
/// No hardcoded gap types, fully extensible through type parameter.
public struct GapType<T: Hashable & Codable & Sendable>: Sendable, Codable, Hashable {
    public let value: T

    public init(_ value: T) {
        self.value = value
    }
}
