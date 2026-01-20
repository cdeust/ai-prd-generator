import Foundation
import Domain

/// Executes ReAct actions (search, analyze, conclude)
/// Single Responsibility: Handle action execution and result formatting
public struct ReActActionExecutor: Sendable {
    private let aiProvider: AIProviderPort
    private let codebaseRepository: CodebaseRepositoryPort?
    private let embeddingGenerator: EmbeddingGeneratorPort?

    public init(
        aiProvider: AIProviderPort,
        codebaseRepository: CodebaseRepositoryPort? = nil,
        embeddingGenerator: EmbeddingGeneratorPort? = nil
    ) {
        self.aiProvider = aiProvider
        self.codebaseRepository = codebaseRepository
        self.embeddingGenerator = embeddingGenerator
    }

    /// Execute action and return result
    public func execute(
        action: ReActAction,
        codebaseId: UUID?
    ) async throws -> ReActActionResult {
        switch action.actionType {
        case .searchCodebase:
            return try await searchCodebase(query: action.query, codebaseId: codebaseId)
        case .analyze:
            return try await analyzeInformation(query: action.query)
        case .conclude:
            return concludeTask(conclusion: action.query)
        }
    }

    // MARK: - Private Methods

    private func searchCodebase(
        query: String,
        codebaseId: UUID?
    ) async throws -> ReActActionResult {
        guard let codebaseId = codebaseId,
              let repo = codebaseRepository,
              let embedder = embeddingGenerator else {
            return ReActActionResult(
                success: false,
                summary: "Codebase search not available",
                data: "",
                metadata: [:]
            )
        }

        let embedding = try await embedder.generateEmbedding(text: query)
        let chunks = try await repo.findSimilarChunks(
            projectId: codebaseId,
            queryEmbedding: embedding,
            limit: 3,
            similarityThreshold: 0.6
        )

        let relevantCode = chunks
            .map { "\($0.chunk.filePath):\n\($0.chunk.content)" }
            .joined(separator: "\n\n")

        return ReActActionResult(
            success: !chunks.isEmpty,
            summary: "Found \(chunks.count) relevant code chunks",
            data: relevantCode,
            metadata: ["chunks_found": String(chunks.count)]
        )
    }

    private func analyzeInformation(query: String) async throws -> ReActActionResult {
        let prompt = """
        Analyze the following information:

        \(query)

        Provide key insights, patterns, or conclusions.
        Be specific and actionable.
        """

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.5
        )

        return ReActActionResult(
            success: true,
            summary: "Analysis completed",
            data: response,
            metadata: [:]
        )
    }

    private func concludeTask(conclusion: String) -> ReActActionResult {
        ReActActionResult(
            success: true,
            summary: "Task completed",
            data: conclusion,
            metadata: [:]
        )
    }
}
