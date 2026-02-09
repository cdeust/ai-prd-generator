import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import AIPRDVerificationEngine
import Application
import Foundation

/// Context for wiring use cases together
/// Contains all dependencies needed during use case assembly
struct WiringContext {
    let dependencies: FactoryDependencies
    let promptService: PromptEngineeringService
    let intelligenceTracker: IntelligenceTrackerService?
    let unifiedEngine: UnifiedVerificationEngine?
    let llmVerifier: LLMResponseVerifier
}
