import Foundation
import Domain

/// Extension for context tracking (RAG, Mockup, Clarification)
/// All prdId fields nullable - context gathering happens BEFORE PRD exists
extension IntelligenceTrackerService {

    // MARK: - RAG Context Tracking

    /// Track a RAG retrieval (prdId nullable, updated via upsert when PRD created)
    public func trackRAGRetrieval(
        prdId: UUID? = nil,
        sectionId: UUID? = nil,
        codebaseId: UUID,
        llmInteractionId: UUID? = nil,
        query: String,
        queryType: RAGQueryType,
        retrievedChunks: [RetrievedChunk],
        retrievalMethod: RetrievalMethod,
        reasoningForSelection: String
    ) async throws -> RAGContextTrace {
        updateRAGMetrics(chunksCount: retrievedChunks.count, scores: retrievedChunks.map { $0.score })

        let trace = RAGContextTrace(
            prdId: prdId,
            sectionId: sectionId,
            codebaseId: codebaseId,
            llmInteractionId: llmInteractionId,
            query: query,
            queryType: queryType,
            retrievedChunks: retrievedChunks,
            chunkIds: retrievedChunks.map { $0.chunkId },
            relevanceScores: retrievedChunks.map { $0.score },
            retrievalMethod: retrievalMethod,
            reasoningForSelection: reasoningForSelection
        )

        try await ragTracker.recordRetrieval(trace)
        return trace
    }

    /// Update prdId for RAG traces when PRD is created
    public func updateRAGRetrievalPrdId(codebaseId: UUID, prdId: UUID) async throws {
        try await ragTracker.updatePrdId(codebaseId: codebaseId, prdId: prdId)
    }

    // MARK: - Mockup Analysis Tracking

    /// Track a mockup analysis (prdId nullable, updated via upsert when PRD created)
    public func trackMockupAnalysis(
        mockupId: UUID,
        prdId: UUID? = nil,
        llmInteractionId: UUID? = nil,
        analysisPrompt: String,
        llmResponse: String,
        detectedPatterns: [DetectedUIPattern] = [],
        uiComponents: [String] = [],
        colorScheme: ColorSchemeInfo? = nil,
        layoutType: String? = nil,
        uncertainties: [String] = [],
        clarificationQuestions: [String] = [],
        influencedSections: [UUID] = [],
        confidenceScore: Double? = nil,
        visionModel: String,
        visionProvider: String
    ) async throws -> MockupAnalysisTrace {
        let trace = MockupAnalysisTrace(
            mockupId: mockupId,
            prdId: prdId,
            llmInteractionId: llmInteractionId,
            analysisPrompt: analysisPrompt,
            llmResponse: llmResponse,
            detectedPatterns: detectedPatterns,
            uiComponents: uiComponents,
            colorScheme: colorScheme,
            layoutType: layoutType,
            uncertainties: uncertainties,
            clarificationQuestions: clarificationQuestions,
            influencedSections: influencedSections,
            confidenceScore: confidenceScore,
            visionModel: visionModel,
            visionProvider: visionProvider
        )

        try await mockupTracker.recordAnalysis(trace)
        return trace
    }

    /// Update prdId for mockup traces when PRD is created
    public func updateMockupAnalysisPrdId(mockupId: UUID, prdId: UUID) async throws {
        try await mockupTracker.updatePrdId(mockupId: mockupId, prdId: prdId)
    }

    // MARK: - Clarification Tracking

    /// Track a clarification question (prdId nullable, updated via upsert when PRD created)
    /// Includes coherence scoring to filter low-value questions before asking
    public func trackClarification(
        prdId: UUID? = nil,
        questionId: UUID,
        questionText: String,
        questionCategory: ClarificationCategory? = nil,
        reasoningForAsking: String,
        gapAddressed: String,
        userAnswer: String? = nil,
        answerTimestamp: Date? = nil,
        impactOnPrd: String? = nil,
        influencedSections: [UUID] = [],
        coherenceScore: Double? = nil,
        valueAddScore: Double? = nil,
        wasAskedToUser: Bool = true
    ) async throws -> ClarificationTrace {
        let trace = ClarificationTrace(
            prdId: prdId,
            questionId: questionId,
            questionText: questionText,
            questionCategory: questionCategory,
            reasoningForAsking: reasoningForAsking,
            gapAddressed: gapAddressed,
            userAnswer: userAnswer,
            answerTimestamp: answerTimestamp,
            impactOnPrd: impactOnPrd,
            influencedSections: influencedSections,
            coherenceScore: coherenceScore,
            valueAddScore: valueAddScore,
            wasAskedToUser: wasAskedToUser
        )

        try await clarificationTracker.recordClarification(trace)
        return trace
    }

    /// Update prdId for clarification traces when PRD is created
    public func updateClarificationPrdId(questionId: UUID, prdId: UUID) async throws {
        try await clarificationTracker.updatePrdId(questionId: questionId, prdId: prdId)
    }
}
