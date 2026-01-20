import Foundation

/// Annotation on mockup
/// Following Single Responsibility Principle - represents mockup annotation
public struct Annotation: Identifiable, Sendable, Codable {
    public let id: UUID
    public let text: String
    public let position: AnnotationPosition

    public init(
        id: UUID = UUID(),
        text: String,
        position: AnnotationPosition
    ) {
        self.id = id
        self.text = text
        self.position = position
    }
}
