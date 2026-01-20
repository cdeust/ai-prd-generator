import Foundation
import Domain
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
