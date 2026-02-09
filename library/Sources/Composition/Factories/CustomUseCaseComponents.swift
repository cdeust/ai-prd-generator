import AIPRDOrchestrationEngine
import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities
import Application

/// Components needed for custom use case creation
struct CustomUseCaseComponents {
    let promptService: PromptEngineeringService
    let tokenizer: TokenizerPort?
    let compressor: AppleIntelligenceContextCompressor?
    let intelligenceTracker: IntelligenceTrackerService?
    let contextBuilder: EnrichedContextBuilder?
}
