import Foundation

/// UI element extracted from mockup
/// Following Single Responsibility Principle - represents UI element
public struct UIElement: Identifiable, Sendable, Codable {
    public let id: UUID
    public let type: UIElementType
    public let label: String?
    public let bounds: ElementBounds

    public init(
        id: UUID = UUID(),
        type: UIElementType,
        label: String? = nil,
        bounds: ElementBounds
    ) {
        self.id = id
        self.type = type
        self.label = label
        self.bounds = bounds
    }
}
