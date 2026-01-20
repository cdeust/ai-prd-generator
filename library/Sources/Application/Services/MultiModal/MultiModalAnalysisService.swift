import Foundation
import Domain

/// Service for orchestrating multi-modal PRD input analysis
///
/// Combines analysis of:
/// - Text descriptions (user requirements)
/// - UI mockups (visual designs)
/// - Codebase context (existing code)
///
/// Provides comprehensive understanding for PRD generation.
public actor MultiModalAnalysisService: Sendable {
    private let visionPort: VisionAnalysisPort
    private let codebasePort: CodebaseRepositoryPort
    private let searchPort: VectorSearchPort

    public init(
        visionPort: VisionAnalysisPort,
        codebasePort: CodebaseRepositoryPort,
        searchPort: VectorSearchPort
    ) {
        self.visionPort = visionPort
        self.codebasePort = codebasePort
        self.searchPort = searchPort
    }

    /// Analyze all inputs comprehensively
    ///
    /// - Parameters:
    ///   - textDescription: User's text description of requirements
    ///   - mockupImages: UI mockup images (optional)
    ///   - codebaseId: Codebase identifier for context (optional)
    /// - Returns: Combined multi-modal analysis result
    public func analyzeInputs(
        textDescription: String,
        mockupImages: [MockupImage],
        codebaseId: UUID?
    ) async throws -> MultiModalAnalysisResult {
        // Analyze mockups concurrently
        let mockupResults = try await analyzeMockups(mockupImages)

        // Extract codebase context if provided
        let codebaseContext: CodebaseContext?
        if let codebaseId = codebaseId {
            codebaseContext = try await extractCodebaseContext(codebaseId: codebaseId)
        } else {
            codebaseContext = nil
        }

        // Combine results
        return MultiModalAnalysisResult(
            textDescription: textDescription,
            mockupAnalysis: mockupResults,
            codebaseContext: codebaseContext,
            analyzedAt: Date()
        )
    }

    /// Analyze mockups and extract user flows
    ///
    /// - Parameter images: Mockup images to analyze
    /// - Returns: Analysis results with extracted flows
    private func analyzeMockups(
        _ images: [MockupImage]
    ) async throws -> [MockupAnalysisResult] {
        guard !images.isEmpty else { return [] }

        // Analyze each mockup
        let results = try await withThrowingTaskGroup(
            of: MockupAnalysisResult.self
        ) { group in
            for image in images {
                group.addTask {
                    try await self.visionPort.analyzeMockup(
                        imageData: image.data,
                        prompt: nil
                    )
                }
            }

            var collected: [MockupAnalysisResult] = []
            for try await result in group {
                collected.append(result)
            }
            return collected
        }

        // Extract user flows across screens
        if results.count > 1 {
            let flows = try await visionPort.extractUserFlows(from: results)

            // Enhance first result with cross-screen flows
            if !results.isEmpty {
                var enhanced = results
                enhanced[0] = MockupAnalysisResult(
                    id: results[0].id,
                    mockupId: results[0].mockupId,
                    analyzedAt: results[0].analyzedAt,
                    components: results[0].components,
                    flows: flows,
                    interactions: results[0].interactions,
                    dataRequirements: results[0].dataRequirements,
                    metadata: results[0].metadata,
                    screenName: results[0].screenName,
                    screenDescription: results[0].screenDescription
                )
                return enhanced
            }
        }

        return results
    }

    /// Extract relevant codebase context
    ///
    /// - Parameter codebaseId: Codebase identifier
    /// - Returns: Codebase context with relevant code chunks
    private func extractCodebaseContext(
        codebaseId: UUID
    ) async throws -> CodebaseContext? {
        // Fetch codebase metadata
        guard let codebase = try await codebasePort.getCodebase(by: codebaseId) else {
            return nil
        }

        // Get relevant code chunks (limit to prevent token overflow)
        let chunks = try await codebasePort.findChunksByProject(
            codebaseId,
            limit: 50,
            offset: 0
        )

        // Determine repository type from URL/path
        let repoType: RepositoryType
        if let repoUrl = codebase.repositoryUrl {
            if repoUrl.contains("github.com") {
                repoType = .github
            } else if repoUrl.contains("gitlab.com") {
                repoType = .gitlab
            } else if repoUrl.contains("bitbucket.org") {
                repoType = .bitbucket
            } else {
                repoType = .local
            }
        } else {
            repoType = .local
        }

        return CodebaseContext(
            codebaseId: codebaseId,
            projectName: codebase.name,
            repositoryType: repoType,
            totalFiles: chunks.count,
            relevantChunks: chunks
        )
    }
}
