import Foundation
import Domain

/// UI insights extracted from mockup analysis
public struct UIInsights: Sendable, Equatable {
    /// Total number of screens analyzed
    public let totalScreens: Int

    /// Total UI components identified
    public let totalComponents: Int

    /// User flows identified
    public let userFlows: [UserFlow]

    /// Interactions detected
    public let interactions: [Interaction]

    /// Component breakdown by type
    public let componentBreakdown: [String: Int]

    public init(
        totalScreens: Int,
        totalComponents: Int,
        userFlows: [UserFlow],
        interactions: [Interaction],
        componentBreakdown: [String: Int]
    ) {
        self.totalScreens = totalScreens
        self.totalComponents = totalComponents
        self.userFlows = userFlows
        self.interactions = interactions
        self.componentBreakdown = componentBreakdown
    }

    /// Average components per screen
    public var averageComponentsPerScreen: Double {
        guard totalScreens > 0 else { return 0.0 }
        return Double(totalComponents) / Double(totalScreens)
    }

    /// Check if UI is complex
    public var isComplex: Bool {
        totalScreens > 5 || totalComponents > 50
    }

    /// Most common component type
    public var mostCommonComponent: String? {
        componentBreakdown.max(by: { $0.value < $1.value })?.key
    }
}
