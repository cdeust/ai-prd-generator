import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import XCTest
@testable import Application
@testable import Domain

/// Production validation for HybridSearchService with 1M samples
///
/// **Purpose:** Validate IMPLEMENTATION correctness at scale
/// If tests fail, the IMPLEMENTATION has bugs that need fixing
///
/// **Statistical Rigor:**
/// - N=1,000,000 samples per test (parameterizable)
/// - 95% confidence intervals
/// - Multiple runs for stability verification
/// - Performance benchmarks
///
/// **What We Validate:**
/// - RRF formula correctness across all ranking scenarios
/// - Alpha parameter mathematical behavior
/// - Edge case handling at scale
final class HybridSearchProductionValidation: XCTestCase {

    // MARK: - Configuration

    private var productionSamples: Int {
        if let envValue = ProcessInfo.processInfo.environment["VALIDATION_SAMPLES"],
           let samples = Int(envValue) {
            return samples
        }
        return 1_000_000  // Default: 1M for production validation
    }

    private let stabilityRuns = 5
    private let maxVarianceAcrossRuns = 0.005  // 0.5%

    // MARK: - Test 1: RRF Formula Correctness (Mathematical Validation)

    func testRRF_formula_correctness_1M_samples() async throws {
        let result = await runStatisticalValidation(
            name: "RRF Formula Correctness",
            targetRate: 0.99,  // 99% must match exact RRF math
            generator: generateRRFScenario,
            validator: { scenario in
                await self.validateRRFMath(scenario: scenario)
            }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Test 2: Alpha Parameter - Pure Vector (alpha=1.0)

    func testAlpha_1_0_preserves_vector_ranking_1M_samples() async throws {
        let result = await runStatisticalValidation(
            name: "Alpha=1.0 (Pure Vector)",
            targetRate: 0.99,  // 99% must preserve vector ranking
            generator: generateConflictingRankings,
            validator: { scenario in
                await self.validatePureVectorRanking(scenario: scenario)
            }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Test 3: Alpha Parameter - Pure Keyword (alpha=0.0)

    func testAlpha_0_0_preserves_keyword_ranking_1M_samples() async throws {
        let result = await runStatisticalValidation(
            name: "Alpha=0.0 (Pure Keyword)",
            targetRate: 0.99,  // 99% must preserve keyword ranking
            generator: generateConflictingRankings,
            validator: { scenario in
                await self.validatePureKeywordRanking(scenario: scenario)
            }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Test 4: Alpha Parameter - Balanced (alpha=0.5)

    func testAlpha_0_5_balanced_weighting_1M_samples() async throws {
        let result = await runStatisticalValidation(
            name: "Alpha=0.5 (Balanced)",
            targetRate: 0.95,  // 95% must show balanced behavior
            generator: generateBalancedScenario,
            validator: { scenario in
                await self.validateBalancedWeighting(scenario: scenario)
            }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Test Scenario Generators

    private struct RRFScenario {
        let vectorResults: [SimilarCodeChunk]
        let keywordResults: [FullTextSearchResult]
        let alpha: Double
        let expectedTopChunkId: UUID
        let expectedScore: Double
    }

    private func generateRRFScenario() -> RRFScenario {
        let projectId = UUID()

        // Create 3-5 chunks
        let numChunks = Int.random(in: 3...5)
        var chunks: [(id: UUID, chunk: CodeChunk)] = []

        for _ in 0..<numChunks {
            let id = UUID()
            let chunk = createTestChunk(id: id)
            chunks.append((id, chunk))
        }

        // Random rankings
        let vectorRanks = chunks.shuffled()
        let keywordRanks = chunks.shuffled()

        let vectorResults = vectorRanks.enumerated().map { (rank, item) in
            SimilarCodeChunk(chunk: item.chunk, similarity: 1.0 - Double(rank) * 0.1)
        }

        let keywordResults = keywordRanks.enumerated().map { (rank, item) in
            FullTextSearchResult(chunk: item.chunk, bm25Score: Float(10.0 - Double(rank)), rank: rank)
        }

        let alpha = Double.random(in: 0.0...1.0)

        // Calculate expected top result with RRF
        var scores: [UUID: Double] = [:]
        for (rank, result) in vectorResults.enumerated() {
            let rrfScore = 1.0 / Double(rank + 60)
            scores[result.chunk.id, default: 0.0] += rrfScore * alpha
        }
        for (rank, result) in keywordResults.enumerated() {
            let rrfScore = 1.0 / Double(rank + 60)
            scores[result.chunk.id, default: 0.0] += rrfScore * (1 - alpha)
        }

        let expectedTop = scores.max(by: { $0.value < $1.value })!

        return RRFScenario(
            vectorResults: vectorResults,
            keywordResults: keywordResults,
            alpha: alpha,
            expectedTopChunkId: expectedTop.key,
            expectedScore: expectedTop.value
        )
    }

    private func generateConflictingRankings() -> RRFScenario {
        let chunk1 = createTestChunk(id: UUID())
        let chunk2 = createTestChunk(id: UUID())

        // Random similarities - Vector: chunk1 > chunk2
        let chunk1VectorSim = Double.random(in: 0.75...0.95)
        let chunk2VectorSim = Double.random(in: 0.3...0.65)

        let vectorResults = [
            SimilarCodeChunk(chunk: chunk1, similarity: chunk1VectorSim),
            SimilarCodeChunk(chunk: chunk2, similarity: chunk2VectorSim)
        ]

        // Random scores - Keyword: chunk2 > chunk1 (opposite ranking)
        let chunk2KeywordScore = Float.random(in: 8.0...12.0)
        let chunk1KeywordScore = Float.random(in: 3.0...6.0)

        let keywordResults = [
            FullTextSearchResult(chunk: chunk2, bm25Score: chunk2KeywordScore, rank: 0),
            FullTextSearchResult(chunk: chunk1, bm25Score: chunk1KeywordScore, rank: 1)
        ]

        return RRFScenario(
            vectorResults: vectorResults,
            keywordResults: keywordResults,
            alpha: 0.5,
            expectedTopChunkId: chunk2.id,  // Will vary by alpha
            expectedScore: 0.0
        )
    }

    private func generateBalancedScenario() -> RRFScenario {
        let chunk1 = createTestChunk(id: UUID())
        let chunk2 = createTestChunk(id: UUID())
        let chunk3 = createTestChunk(id: UUID())

        // Random similarities - chunk1 good in both, chunk2 only vector, chunk3 only keyword
        let chunk1VectorSim = Double.random(in: 0.85...0.95)  // High in vector
        let chunk2VectorSim = Double.random(in: 0.75...0.85)  // Medium in vector
        let chunk3VectorSim = Double.random(in: 0.4...0.6)    // Low in vector

        let vectorResults = [
            SimilarCodeChunk(chunk: chunk1, similarity: chunk1VectorSim),  // rank 0
            SimilarCodeChunk(chunk: chunk2, similarity: chunk2VectorSim),  // rank 1
            SimilarCodeChunk(chunk: chunk3, similarity: chunk3VectorSim)   // rank 2
        ]

        // Random scores - chunk1 good in keyword, chunk3 medium, chunk2 low
        let chunk1KeywordScore = Float.random(in: 9.0...12.0)  // High
        let chunk3KeywordScore = Float.random(in: 6.0...9.0)   // Medium
        let chunk2KeywordScore = Float.random(in: 2.0...4.0)   // Low

        let keywordResults = [
            FullTextSearchResult(chunk: chunk1, bm25Score: chunk1KeywordScore, rank: 0),
            FullTextSearchResult(chunk: chunk3, bm25Score: chunk3KeywordScore, rank: 1),
            FullTextSearchResult(chunk: chunk2, bm25Score: chunk2KeywordScore, rank: 2)
        ]

        // With alpha=0.5: chunk1 should win (good in both)
        return RRFScenario(
            vectorResults: vectorResults,
            keywordResults: keywordResults,
            alpha: 0.5,
            expectedTopChunkId: chunk1.id,
            expectedScore: 0.0
        )
    }

    // MARK: - Validators

    private func validateRRFMath(scenario: RRFScenario) async -> Bool {
        let service = createService(
            vectorResults: scenario.vectorResults,
            keywordResults: scenario.keywordResults
        )

        guard let results = try? await service.search(
            query: "test",
            projectId: UUID(),
            limit: 10,
            alpha: scenario.alpha
        ) else {
            return false
        }

        guard let topResult = results.first else { return false }

        // Validate top result matches expected
        if topResult.chunk.id != scenario.expectedTopChunkId {
            return false
        }

        // Validate score calculation (within floating point tolerance)
        let scoreDiff = abs(topResult.hybridScore - scenario.expectedScore)
        return scoreDiff < 0.0001 || scenario.expectedScore == 0.0  // 0.0 means we don't check
    }

    private func validatePureVectorRanking(scenario: RRFScenario) async -> Bool {
        let service = createService(
            vectorResults: scenario.vectorResults,
            keywordResults: scenario.keywordResults
        )

        guard let results = try? await service.search(
            query: "test",
            projectId: UUID(),
            alpha: 1.0  // Pure vector
        ) else {
            return false
        }

        // Should match vector ranking exactly
        guard results.count >= 2 else { return false }
        return results[0].chunk.id == scenario.vectorResults[0].chunk.id &&
               results[1].chunk.id == scenario.vectorResults[1].chunk.id
    }

    private func validatePureKeywordRanking(scenario: RRFScenario) async -> Bool {
        let service = createService(
            vectorResults: scenario.vectorResults,
            keywordResults: scenario.keywordResults
        )

        guard let results = try? await service.search(
            query: "test",
            projectId: UUID(),
            alpha: 0.0  // Pure keyword
        ) else {
            return false
        }

        // Should match keyword ranking exactly
        guard results.count >= 2 else { return false }
        return results[0].chunk.id == scenario.keywordResults[0].chunk.id &&
               results[1].chunk.id == scenario.keywordResults[1].chunk.id
    }

    private func validateBalancedWeighting(scenario: RRFScenario) async -> Bool {
        let service = createService(
            vectorResults: scenario.vectorResults,
            keywordResults: scenario.keywordResults
        )

        guard let results = try? await service.search(
            query: "test",
            projectId: UUID(),
            alpha: 0.5
        ) else {
            return false
        }

        guard let topResult = results.first else { return false }
        return topResult.chunk.id == scenario.expectedTopChunkId
    }

    // MARK: - Helpers

    private func createService(
        vectorResults: [SimilarCodeChunk],
        keywordResults: [FullTextSearchResult]
    ) -> HybridSearchService {
        let embedding = [Float](repeating: 1.0, count: 10)
        return HybridSearchService(
            codebaseRepository: MockCodebaseRepository(vectorResults: vectorResults),
            embeddingGenerator: MockEmbeddingGenerator(embedding: embedding),
            fullTextSearch: MockFullTextSearch(results: keywordResults)
        )
    }

    private func createTestChunk(id: UUID) -> CodeChunk {
        CodeChunk(
            id: id,
            fileId: UUID(),
            codebaseId: UUID(),
            projectId: UUID(),
            filePath: "test.swift",
            content: "test content",
            contentHash: "hash",
            startLine: 1,
            endLine: 10,
            chunkType: .function,
            language: .swift,
            tokenCount: 50
        )
    }

    // MARK: - Statistical Validation Framework

    private struct ValidationResult {
        let passed: Bool
        let failureMessage: String
        let mean: Double
        let ci95Lower: Double
        let ci95Upper: Double
        let performanceNs: Double
        let runsVariance: Double
    }

    private func runStatisticalValidation(
        name: String,
        targetRate: Double,
        generator: @escaping () -> RRFScenario,
        validator: @escaping (RRFScenario) async -> Bool
    ) async -> ValidationResult {

        print("\n" + String(repeating: "=", count: 80))
        print("🔬 PRODUCTION VALIDATION: \(name)")
        print(String(repeating: "=", count: 80))
        print("Target: \(Int(targetRate * 100))% correctness rate")
        print("Samples: \(productionSamples.formatted())")
        print("Stability runs: \(stabilityRuns)")

        var rates: [Double] = []
        var performanceMeasurements: [Double] = []

        for run in 1...stabilityRuns {
            print("\n📊 Run \(run)/\(stabilityRuns)...")

            let startTime = Date()
            var correctCount = 0

            for i in 0..<productionSamples {
                let scenario = generator()

                if await validator(scenario) {
                    correctCount += 1
                }

                if (i + 1) % 100_000 == 0 {
                    let progress = Double(i + 1) / Double(productionSamples) * 100
                    print("  [\(String(format: "%.0f", progress))%] \(i + 1) samples processed...")
                }
            }

            let elapsed = Date().timeIntervalSince(startTime)
            let rate = Double(correctCount) / Double(productionSamples)

            rates.append(rate)
            performanceMeasurements.append(elapsed)

            print("  ✓ Rate: \(String(format: "%.4f", rate)) (\(Int(rate * 100))%)")
            print("  ⏱️  Time: \(String(format: "%.2f", elapsed))s")
            print("  ⚡ Throughput: \(String(format: "%.0f", Double(productionSamples) / elapsed)) samples/sec")
        }

        // Calculate statistics
        let mean = rates.reduce(0.0, +) / Double(rates.count)
        let variance = rates.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(rates.count)
        let stdDev = sqrt(variance)

        let standardError = stdDev / sqrt(Double(rates.count))
        let ci95Margin = 1.96 * standardError
        let ci95Lower = mean - ci95Margin
        let ci95Upper = mean + ci95Margin

        let runsVariance = stdDev / mean

        let avgPerformance = performanceMeasurements.reduce(0.0, +) / Double(performanceMeasurements.count)
        let avgThroughput = Double(productionSamples) / avgPerformance
        let performanceAcceptable = avgPerformance < 60.0

        print("\n" + String(repeating: "-", count: 80))
        print("📈 STATISTICAL SUMMARY")
        print(String(repeating: "-", count: 80))
        print("Mean rate:        \(String(format: "%.4f", mean)) (\(Int(mean * 100))%)")
        print("Std deviation:    \(String(format: "%.4f", stdDev))")
        print("95% CI:           [\(String(format: "%.4f", ci95Lower)), \(String(format: "%.4f", ci95Upper))]")
        print("Runs variance:    \(String(format: "%.2f", runsVariance * 100))% (target: <0.5%)")
        print("Avg performance:  \(String(format: "%.2f", avgPerformance))s")
        print("Avg throughput:   \(String(format: "%.0f", avgThroughput)) samples/sec")

        let targetMet = ci95Lower > targetRate
        let stabilityMet = runsVariance < maxVarianceAcrossRuns
        let performanceMet = performanceAcceptable

        print("\n" + String(repeating: "-", count: 80))
        print("✅ VALIDATION CHECKS")
        print(String(repeating: "-", count: 80))
        print("Target met (CI > \(Int(targetRate * 100))%):  \(targetMet ? "✅ PASS" : "❌ FAIL")")
        print("Stability met (<0.5% var):    \(stabilityMet ? "✅ PASS" : "❌ FAIL")")
        print("Performance met (<60s):       \(performanceMet ? "✅ PASS" : "❌ FAIL")")

        let allPassed = targetMet && stabilityMet && performanceMet

        if allPassed {
            print("\n🎉 VALIDATION PASSED")
        } else {
            print("\n❌ VALIDATION FAILED - IMPLEMENTATION HAS BUGS")
        }
        print(String(repeating: "=", count: 80) + "\n")

        let failureMessage = """
        \(name) validation failed - IMPLEMENTATION NEEDS FIXING:
          Mean rate: \(String(format: "%.4f", mean)) (\(Int(mean * 100))%),
          95% CI: [\(String(format: "%.4f", ci95Lower)), \(String(format: "%.4f", ci95Upper))]]
          Target: \(String(format: "%.4f", targetRate)) (\(Int(targetRate * 100))%)
          Runs variance: \(String(format: "%.2f", runsVariance * 100))%
          Performance: \(String(format: "%.2f", avgPerformance))s
        """

        return ValidationResult(
            passed: allPassed,
            failureMessage: failureMessage,
            mean: mean,
            ci95Lower: ci95Lower,
            ci95Upper: ci95Upper,
            performanceNs: avgPerformance,
            runsVariance: runsVariance
        )
    }
}

// MARK: - Mock Ports (Reused from Spec)

private final class MockCodebaseRepository: CodebaseRepositoryPort {
    private let vectorResults: [SimilarCodeChunk]
    init(vectorResults: [SimilarCodeChunk]) { self.vectorResults = vectorResults }
    func findSimilarChunks(projectId: UUID, queryEmbedding: [Float], limit: Int, similarityThreshold: Float) async throws -> [SimilarCodeChunk] { vectorResults }
    func createCodebase(_ codebase: Codebase) async throws -> Codebase { fatalError() }
    func getCodebase(by id: UUID) async throws -> Codebase? { fatalError() }
    func listCodebases(forUser userId: UUID) async throws -> [Codebase] { fatalError() }
    func updateCodebase(_ codebase: Codebase) async throws -> Codebase { fatalError() }
    func deleteCodebase(_ id: UUID) async throws { fatalError() }
    func saveProject(_ project: CodebaseProject) async throws -> CodebaseProject { fatalError() }
    func findProjectById(_ id: UUID) async throws -> CodebaseProject? { fatalError() }
    func findProjectByRepository(url: String, branch: String) async throws -> CodebaseProject? { fatalError() }
    func updateProject(_ project: CodebaseProject) async throws -> CodebaseProject { fatalError() }
    func deleteProject(_ id: UUID) async throws { fatalError() }
    func updateProjectIndexingError(projectId: UUID, error: String) async throws { fatalError() }
    func listProjects(limit: Int, offset: Int) async throws -> [CodebaseProject] { fatalError() }
    func saveFiles(_ files: [CodeFile], projectId: UUID) async throws -> [CodeFile] { fatalError() }
    func addFile(_ file: CodeFile) async throws -> CodeFile { fatalError() }
    func findFilesByProject(_ projectId: UUID) async throws -> [CodeFile] { fatalError() }
    func findFile(projectId: UUID, path: String) async throws -> CodeFile? { fatalError() }
    func updateFileParsed(fileId: UUID, isParsed: Bool, error: String?) async throws { fatalError() }
    func saveChunks(_ chunks: [CodeChunk], projectId: UUID) async throws -> [CodeChunk] { fatalError() }
    func findChunksByProject(_ projectId: UUID, limit: Int, offset: Int) async throws -> [CodeChunk] { fatalError() }
    func findChunksByFile(_ fileId: UUID) async throws -> [CodeChunk] { fatalError() }
    func findChunksInFile(codebaseId: UUID, filePath: String, endLineBefore: Int?, startLineAfter: Int?, limit: Int) async throws -> [CodeChunk] { fatalError() }
    func deleteChunksByProject(_ projectId: UUID) async throws { fatalError() }
    func saveEmbeddings(_ embeddings: [CodeEmbedding], projectId: UUID) async throws { fatalError() }
    func searchFiles(in codebaseId: UUID, embedding: [Float], limit: Int, similarityThreshold: Float?) async throws -> [(file: CodeFile, similarity: Float)] { fatalError() }
    func saveMerkleRoot(projectId: UUID, rootHash: String) async throws { fatalError() }
    func getMerkleRoot(projectId: UUID) async throws -> String? { fatalError() }
    func saveMerkleNodes(_ nodes: [MerkleNode], projectId: UUID) async throws { fatalError() }
    func getMerkleNodes(projectId: UUID) async throws -> [MerkleNode] { fatalError() }
}

private final class MockEmbeddingGenerator: EmbeddingGeneratorPort {
    private let embedding: [Float]
    init(embedding: [Float]) { self.embedding = embedding }
    func generateEmbedding(text: String) async throws -> [Float] { embedding }
    func generateEmbeddings(texts: [String]) async throws -> [[Float]] { texts.map { _ in embedding } }
    func generateCodeEmbedding(chunk: CodeChunk) async throws -> CodeEmbedding { fatalError() }
    var dimension: Int { embedding.count }
    var modelName: String { "test" }
    var embeddingVersion: Int { 1 }
}

private final class MockFullTextSearch: FullTextSearchPort {
    private let results: [FullTextSearchResult]
    init(results: [FullTextSearchResult]) { self.results = results }
    func searchChunks(in codebaseId: UUID, query: String, limit: Int, minScore: Float) async throws -> [FullTextSearchResult] { results }
    func searchFiles(in codebaseId: UUID, query: String, limit: Int) async throws -> [(file: CodeFile, bm25Score: Float)] { fatalError() }
}
