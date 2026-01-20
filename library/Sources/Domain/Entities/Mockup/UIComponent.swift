import Foundation

/// UI component extracted from mockup analysis
public struct UIComponent: Sendable, Codable, Equatable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Component type
    public let type: ComponentType

    /// Visible label or text
    public let label: String?

    /// Position and size
    public let position: ComponentPosition

    /// Current state
    public let state: ComponentState?

    /// Available actions
    public let actions: [ComponentAction]

    /// Custom properties
    public let properties: [String: String]

    /// Accessibility label
    public let accessibilityLabel: String?

    public init(
        id: UUID = UUID(),
        type: ComponentType,
        label: String? = nil,
        position: ComponentPosition,
        state: ComponentState? = nil,
        actions: [ComponentAction] = [],
        properties: [String: String] = [:],
        accessibilityLabel: String? = nil
    ) {
        self.id = id
        self.type = type
        self.label = label
        self.position = position
        self.state = state
        self.actions = actions
        self.properties = properties
        self.accessibilityLabel = accessibilityLabel
    }

    /// Check if component is interactive
    public var isInteractive: Bool {
        !actions.isEmpty
    }

    /// Check if component is an input field
    public var isInputField: Bool {
        switch type {
        case .textField, .passwordField, .searchField, .textArea, .picker, .datePicker:
            return true
        default:
            return false
        }
    }
}
