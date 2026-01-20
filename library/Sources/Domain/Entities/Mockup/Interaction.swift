import Foundation

/// User interaction with a UI component
public struct Interaction: Sendable, Codable, Equatable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Trigger that initiates this interaction
    public let trigger: InteractionTrigger

    /// Source component ID
    public let sourceComponentId: UUID

    /// Target screen ID (if navigation occurs)
    public let targetScreenId: UUID?

    /// Feedback provided
    public let feedback: InteractionFeedback?

    /// Conditions for this interaction
    public let conditions: [String]

    /// Description of the interaction
    public let description: String?

    public init(
        id: UUID = UUID(),
        trigger: InteractionTrigger,
        sourceComponentId: UUID,
        targetScreenId: UUID? = nil,
        feedback: InteractionFeedback? = nil,
        conditions: [String] = [],
        description: String? = nil
    ) {
        self.id = id
        self.trigger = trigger
        self.sourceComponentId = sourceComponentId
        self.targetScreenId = targetScreenId
        self.feedback = feedback
        self.conditions = conditions
        self.description = description
    }

    /// Check if interaction causes navigation
    public var causesNavigation: Bool {
        targetScreenId != nil
    }

    /// Check if interaction has conditions
    public var isConditional: Bool {
        !conditions.isEmpty
    }

    /// Check if interaction provides feedback
    public var providesFeedback: Bool {
        feedback != nil
    }
}
