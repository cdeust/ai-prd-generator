import Foundation

/// Annotation position on mockup
/// Following Single Responsibility Principle - represents annotation position
public struct AnnotationPosition: Sendable, Codable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}
