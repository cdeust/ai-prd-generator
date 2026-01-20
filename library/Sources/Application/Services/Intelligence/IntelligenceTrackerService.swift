import Foundation
import Domain

/// Service for tracking all intelligence data during PRD analysis and generation
/// All tracking happens BEFORE PRD creation - prdId is updated via upsert after PRD exists
public final class IntelligenceTrackerService: @unchecked Sendable {
    public let llmTracker: LLMInteractionTrackerPort
    public let strategyTracker: StrategyDecisionTrackerPort
    public let ragTracker: RAGContextTrackerPort
    public let mockupTracker: MockupAnalysisTrackerPort
    public let clarificationTracker: ClarificationTrackerPort
    public let thinkingChainTracker: ThinkingChainTrackerPort
    public let metricsTracker: PerformanceMetricsTrackerPort
    let costCalculator: LLMCostCalculator

    // Track cumulative metrics during analysis
    private var totalTokens: Int = 0
    private var totalCost: Double = 0
    private var ragQueriesCount: Int = 0
    private var ragChunksUsed: Int = 0
    private var relevanceScores: [Double] = []
    private var startTime: Date?

    public init(
        llmTracker: LLMInteractionTrackerPort,
        strategyTracker: StrategyDecisionTrackerPort,
        ragTracker: RAGContextTrackerPort,
        mockupTracker: MockupAnalysisTrackerPort,
        clarificationTracker: ClarificationTrackerPort,
        thinkingChainTracker: ThinkingChainTrackerPort,
        metricsTracker: PerformanceMetricsTrackerPort
    ) {
        self.llmTracker = llmTracker
        self.strategyTracker = strategyTracker
        self.ragTracker = ragTracker
        self.mockupTracker = mockupTracker
        self.clarificationTracker = clarificationTracker
        self.thinkingChainTracker = thinkingChainTracker
        self.metricsTracker = metricsTracker
        self.costCalculator = LLMCostCalculator()
    }

    /// Start tracking a new PRD generation session (includes analysis and generation phases)
    public func startGeneration() {
        startTime = Date()
        totalTokens = 0
        totalCost = 0
        ragQueriesCount = 0
        ragChunksUsed = 0
        relevanceScores = []
    }

    /// Update cumulative token metrics
    func updateTokenMetrics(tokens: Int?, cost: Double?) {
        if let tokens = tokens { totalTokens += tokens }
        if let cost = cost { totalCost += cost }
    }

    /// Update cumulative RAG metrics
    func updateRAGMetrics(chunksCount: Int, scores: [Double]) {
        ragQueriesCount += 1
        ragChunksUsed += chunksCount
        relevanceScores.append(contentsOf: scores)
    }

    /// Finalize and save performance metrics after PRD is created
    public func finalizeMetrics(
        prdId: UUID,
        strategyUsed: String?,
        qualityScore: Double? = nil
    ) async throws {
        let generationTime = startTime.map { Int(Date().timeIntervalSince($0)) }
        let avgRelevance = relevanceScores.isEmpty
            ? nil
            : relevanceScores.reduce(0, +) / Double(relevanceScores.count)

        let metrics = PRDPerformanceMetrics(
            prdId: prdId,
            qualityScore: qualityScore,
            totalGenerationTimeSeconds: generationTime,
            totalTokensUsed: totalTokens > 0 ? totalTokens : nil,
            totalCostUsd: totalCost > 0 ? totalCost : nil,
            strategyUsed: strategyUsed,
            ragQueriesCount: ragQueriesCount > 0 ? ragQueriesCount : nil,
            ragChunksUsed: ragChunksUsed > 0 ? ragChunksUsed : nil,
            ragRelevanceAvg: avgRelevance
        )

        try await metricsTracker.saveMetrics(metrics)
    }
}
