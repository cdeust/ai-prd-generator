import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities
import Application
import InfrastructureCore

/// Components needed for PRD use case creation
/// Single Responsibility: Group related dependencies for factory use
struct PRDComponents {
    let tokenizer: TokenizerPort?
    let compressor: AppleIntelligenceContextCompressor?
    let contextBuilder: EnrichedContextBuilder?
    let codebaseRepository: CodebaseRepositoryPort?
    let embeddingGenerator: EmbeddingGeneratorPort?
}
