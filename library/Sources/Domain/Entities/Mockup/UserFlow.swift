import Foundation

/// User flow representing navigation between screens
public struct UserFlow: Sendable, Codable, Equatable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Flow name
    public let name: String

    /// Flow description
    public let description: String?

    /// Flow type
    public let flowType: FlowType

    /// Screens in this flow
    public let screens: [ScreenNode]

    /// Transitions between screens
    public let transitions: [FlowTransition]

    /// Starting screen ID
    public let startScreenId: UUID

    /// Ending screen IDs (can have multiple end points)
    public let endScreenIds: [UUID]

    /// Flow priority
    public let priority: Priority

    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        flowType: FlowType,
        screens: [ScreenNode],
        transitions: [FlowTransition],
        startScreenId: UUID,
        endScreenIds: [UUID],
        priority: Priority = .medium
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.flowType = flowType
        self.screens = screens
        self.transitions = transitions
        self.startScreenId = startScreenId
        self.endScreenIds = endScreenIds
        self.priority = priority
    }

    /// Total number of screens in flow
    public var screenCount: Int {
        screens.count
    }

    /// Total number of transitions
    public var transitionCount: Int {
        transitions.count
    }

    /// Check if flow is linear (each screen has one transition)
    public var isLinear: Bool {
        transitions.count == screens.count - 1
    }

    /// Get all screens that can be reached from start
    public func reachableScreens() -> Set<UUID> {
        var reachable: Set<UUID> = [startScreenId]
        var toVisit = [startScreenId]

        while !toVisit.isEmpty {
            let current = toVisit.removeFirst()

            for transition in transitions where transition.fromScreen == current {
                if !reachable.contains(transition.toScreen) {
                    reachable.insert(transition.toScreen)
                    toVisit.append(transition.toScreen)
                }
            }
        }

        return reachable
    }
}
