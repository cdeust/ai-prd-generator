import Foundation

/// Image dimensions
public struct ImageDimensions: Sendable, Codable, Equatable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public var aspectRatio: Double {
        Double(width) / Double(height)
    }
}
