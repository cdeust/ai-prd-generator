import Foundation

/// Transition between screens in a user flow
public struct FlowTransition: Sendable, Codable, Equatable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Source screen ID
    public let fromScreen: UUID

    /// Destination screen ID
    public let toScreen: UUID

    /// Trigger that causes this transition
    public let trigger: InteractionTrigger

    /// Animation type
    public let animation: TransitionAnimation?

    /// Condition for transition (optional)
    public let condition: String?

    public init(
        id: UUID = UUID(),
        fromScreen: UUID,
        toScreen: UUID,
        trigger: InteractionTrigger,
        animation: TransitionAnimation? = nil,
        condition: String? = nil
    ) {
        self.id = id
        self.fromScreen = fromScreen
        self.toScreen = toScreen
        self.trigger = trigger
        self.animation = animation
        self.condition = condition
    }
}
