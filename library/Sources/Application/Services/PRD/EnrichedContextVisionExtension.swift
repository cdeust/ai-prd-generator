import Foundation
import Domain

/// Extension for vision/mockup context gathering
extension EnrichedContextBuilder {

    func gatherVisionContext(
        _ request: PRDRequest
    ) async throws -> [MockupAnalysisResult]? {
        guard let fileIds = request.mockupFileIds, !fileIds.isEmpty else {
            return nil
        }

        var results: [MockupAnalysisResult] = []

        for fileId in fileIds {
            if let result = try await gatherMockupResult(fileId: fileId) {
                results.append(result)
            }
        }

        return results.isEmpty ? nil : results
    }

    private func gatherMockupResult(fileId: String) async throws -> MockupAnalysisResult? {
        // Try to load from database first
        if let repo = mockupRepository,
           let mockupId = UUID(uuidString: fileId),
           let mockup = try await repo.findById(mockupId) {

            // If already analyzed, use cached result
            if let analysis = mockup.analysisResult {
                return analysis
            }

            // Otherwise, analyze and cache the result
            if let analyzer = visionAnalyzer {
                return try await analyzeAndCacheMockup(
                    mockup: mockup,
                    fileUrl: mockup.fileUrl,
                    analyzer: analyzer,
                    repository: repo
                )
            }
        }

        // Fallback: analyze from filesystem without caching
        if let analyzer = visionAnalyzer {
            if let fileURL = try? findUploadedFile(fileId) {
                let imageData = try Data(contentsOf: fileURL)
                return try await analyzer.analyzeMockup(
                    imageData: imageData,
                    prompt: "Extract UI components, user flows, and data requirements"
                )
            }
        }

        return nil
    }

    private func analyzeAndCacheMockup(
        mockup: Mockup,
        fileUrl: String,
        analyzer: VisionAnalysisPort,
        repository: MockupRepositoryPort
    ) async throws -> MockupAnalysisResult {
        let fileURL = URL(fileURLWithPath: fileUrl)
        let imageData = try Data(contentsOf: fileURL)

        let analysisPrompt = "Extract UI components, user flows, and data requirements"
        let analysis = try await analyzer.analyzeMockup(
            imageData: imageData,
            prompt: analysisPrompt
        )

        // Cache the analysis result in the database
        try await repository.updateAnalysisResult(mockupId: mockup.id, analysisResult: analysis)
        print("📸 Analyzed and cached mockup: \(mockup.name)")

        // Track mockup analysis in intelligence layer (prdId=nil, updated via upsert later)
        if let tracker = intelligenceTracker {
            do {
                _ = try await tracker.trackMockupAnalysis(
                    mockupId: mockup.id,
                    prdId: nil,
                    analysisPrompt: analysisPrompt,
                    llmResponse: analysis.screenDescription ?? "Mockup analyzed",
                    detectedPatterns: [],
                    uiComponents: analysis.components.compactMap { $0.label ?? $0.type.rawValue },
                    layoutType: analysis.layoutType,
                    uncertainties: analysis.uncertainties,
                    clarificationQuestions: analysis.suggestedClarifications,
                    confidenceScore: analysis.metadata.confidence,
                    visionModel: analyzer.modelName,
                    visionProvider: analyzer.providerName
                )
                print("✅ [Intelligence] Tracked mockup analysis: \(mockup.name)")
            } catch {
                print("❌ [Intelligence] Failed to track mockup analysis: \(error)")
            }
        }

        return analysis
    }

    private func findUploadedFile(_ fileId: String) throws -> URL {
        let files = try FileManager.default.contentsOfDirectory(
            at: uploadsDirectory,
            includingPropertiesForKeys: nil
        )

        guard let fileURL = files.first(where: { $0.lastPathComponent.hasPrefix(fileId) }) else {
            throw MockupAnalysisError.providerError("File not found: \(fileId)")
        }

        return fileURL
    }
}
