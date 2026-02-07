import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities
import Application
import InfrastructureCore

/// Factory for creating intelligence tracking and metrics components
/// Following Single Responsibility: Handles intelligence-specific dependency creation
struct IntelligenceFactory: Sendable {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func createIntelligenceTracker() throws -> IntelligenceTrackerService? {
        // Intelligence tracking disabled for standalone skill
        // (No persistence needed - in-memory only)
        return nil
    }
}
