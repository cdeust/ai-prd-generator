import Foundation

/// Position and size of a UI component in a mockup
public struct ComponentPosition: Sendable, Codable, Equatable {
    /// X coordinate (pixels from left)
    public let x: Int

    /// Y coordinate (pixels from top)
    public let y: Int

    /// Width in pixels
    public let width: Int

    /// Height in pixels
    public let height: Int

    /// Optional layout description
    public let layoutDescription: String?

    public init(
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        layoutDescription: String? = nil
    ) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.layoutDescription = layoutDescription
    }

    /// Center point of component
    public var center: (x: Int, y: Int) {
        (x: x + width / 2, y: y + height / 2)
    }

    /// Area in square pixels
    public var area: Int {
        width * height
    }
}
