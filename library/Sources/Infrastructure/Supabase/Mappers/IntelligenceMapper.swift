import Foundation
import Domain

/// Mapper for intelligence layer entities and Supabase records
/// Single Responsibility: Mapping between domain and persistence
public struct IntelligenceMapper: Sendable {

    public init() {}

    // MARK: - LLM Interaction

    public func toRecord(_ trace: LLMInteractionTrace) -> SupabaseLLMInteractionRecord {
        SupabaseLLMInteractionRecord(
            id: trace.id.uuidString.lowercased(),
            prdId: trace.prdId?.uuidString.lowercased(),
            sectionId: trace.sectionId?.uuidString.lowercased(),
            timestamp: trace.timestamp,
            purpose: trace.purpose.rawValue,
            contextType: trace.contextType?.rawValue,
            promptTemplate: trace.promptTemplate,
            actualPrompt: trace.actualPrompt,
            systemInstructions: trace.systemInstructions,
            llmModel: trace.llmModel,
            provider: trace.provider,
            parameters: mapParametersToRecord(trace.parameters),
            response: trace.response,
            responseMetadata: trace.responseMetadata,
            tokensPrompt: trace.tokensPrompt,
            tokensResponse: trace.tokensResponse,
            tokensTotal: trace.tokensTotal,
            latencyMs: trace.latencyMs,
            costUsd: trace.costUsd,
            thinkingStrategy: trace.thinkingStrategy,
            thinkingDepth: trace.thinkingDepth,
            createdAt: trace.createdAt
        )
    }

    public func toDomain(_ record: SupabaseLLMInteractionRecord) -> LLMInteractionTrace? {
        guard let id = UUID(uuidString: record.id),
              let purpose = InteractionPurpose(rawValue: record.purpose) else {
            return nil
        }

        return LLMInteractionTrace(
            id: id,
            prdId: record.prdId.flatMap { UUID(uuidString: $0) },
            sectionId: record.sectionId.flatMap { UUID(uuidString: $0) },
            timestamp: record.timestamp ?? Date(),
            purpose: purpose,
            contextType: record.contextType.flatMap { ContextType(rawValue: $0) },
            promptTemplate: record.promptTemplate,
            actualPrompt: record.actualPrompt,
            systemInstructions: record.systemInstructions,
            llmModel: record.llmModel,
            provider: record.provider,
            parameters: mapParametersToDomain(record.parameters),
            response: record.response,
            responseMetadata: record.responseMetadata,
            tokensPrompt: record.tokensPrompt,
            tokensResponse: record.tokensResponse,
            tokensTotal: record.tokensTotal,
            latencyMs: record.latencyMs,
            costUsd: record.costUsd,
            thinkingStrategy: record.thinkingStrategy,
            thinkingDepth: record.thinkingDepth,
            createdAt: record.createdAt ?? Date()
        )
    }

    // MARK: - Strategy Decision

    public func toRecord(_ decision: ThinkingStrategyDecision) -> SupabaseStrategyDecisionRecord {
        SupabaseStrategyDecisionRecord(
            id: decision.id.uuidString.lowercased(),
            prdId: decision.prdId?.uuidString.lowercased(),
            sectionId: decision.sectionId?.uuidString.lowercased(),
            strategyChosen: decision.strategyChosen,
            reasoning: decision.reasoning,
            confidenceScore: decision.confidenceScore,
            inputCharacteristics: mapCharacteristicsToRecord(decision.inputCharacteristics),
            alternativesConsidered: decision.alternativesConsidered,
            actualPerformance: mapPerformanceToRecord(decision.actualPerformance),
            wasEffective: decision.wasEffective,
            lessonsLearned: decision.lessonsLearned,
            createdAt: decision.createdAt,
            updatedAt: decision.updatedAt
        )
    }

    // MARK: - RAG Context

    public func toRecord(_ trace: RAGContextTrace) -> SupabaseRAGContextRecord {
        SupabaseRAGContextRecord(
            id: trace.id.uuidString.lowercased(),
            prdId: trace.prdId?.uuidString.lowercased(),
            sectionId: trace.sectionId?.uuidString.lowercased(),
            codebaseId: trace.codebaseId.uuidString.lowercased(),
            llmInteractionId: trace.llmInteractionId?.uuidString.lowercased(),
            query: trace.query,
            queryType: trace.queryType.rawValue,
            retrievedChunks: mapChunksToRecord(trace.retrievedChunks),
            chunkIds: trace.chunkIds.map { $0.uuidString.lowercased() },
            relevanceScores: trace.relevanceScores,
            retrievalMethod: trace.retrievalMethod.rawValue,
            reasoningForSelection: trace.reasoningForSelection,
            impactOnOutput: trace.impactOnOutput,
            userFeedback: trace.userFeedback,
            actualUsefulness: trace.actualUsefulness?.rawValue,
            createdAt: trace.createdAt
        )
    }

    // MARK: - Mockup Analysis

    public func toRecord(_ trace: MockupAnalysisTrace) -> SupabaseMockupAnalysisRecord {
        SupabaseMockupAnalysisRecord(
            id: trace.id.uuidString.lowercased(),
            mockupId: trace.mockupId.uuidString.lowercased(),
            prdId: trace.prdId?.uuidString.lowercased(),
            llmInteractionId: trace.llmInteractionId?.uuidString.lowercased(),
            analysisPrompt: trace.analysisPrompt,
            llmResponse: trace.llmResponse,
            detectedPatterns: mapPatternsToRecord(trace.detectedPatterns),
            uiComponents: trace.uiComponents,
            colorScheme: mapColorSchemeToRecord(trace.colorScheme),
            layoutType: trace.layoutType,
            uncertainties: trace.uncertainties,
            clarificationQuestions: trace.clarificationQuestions,
            influencedSections: trace.influencedSections.map { $0.uuidString.lowercased() },
            confidenceScore: trace.confidenceScore,
            visionModel: trace.visionModel,
            visionProvider: trace.visionProvider,
            createdAt: trace.createdAt
        )
    }

    // MARK: - Clarification

    public func toRecord(_ trace: ClarificationTrace) -> SupabaseClarificationRecord {
        SupabaseClarificationRecord(
            id: trace.id.uuidString.lowercased(),
            prdId: trace.prdId?.uuidString.lowercased(),
            questionId: trace.questionId.uuidString.lowercased(),
            questionText: trace.questionText,
            questionCategory: trace.questionCategory?.rawValue,
            reasoningForAsking: trace.reasoningForAsking,
            gapAddressed: trace.gapAddressed,
            userAnswer: trace.userAnswer,
            answerTimestamp: trace.answerTimestamp,
            impactOnPrd: trace.impactOnPrd,
            influencedSections: trace.influencedSections.map { $0.uuidString.lowercased() },
            wasHelpful: trace.wasHelpful,
            improvedQuality: trace.improvedQuality,
            shouldAskAgainForSimilar: trace.shouldAskAgainForSimilar,
            coherenceScore: trace.coherenceScore,
            valueAddScore: trace.valueAddScore,
            wasAskedToUser: trace.wasAskedToUser,
            createdAt: trace.createdAt
        )
    }

    // MARK: - Thinking Chain Step

    public func toRecord(_ step: ThinkingChainStep) -> SupabaseThinkingStepRecord {
        SupabaseThinkingStepRecord(
            id: step.id.uuidString.lowercased(),
            prdId: step.prdId?.uuidString.lowercased(),
            sectionId: step.sectionId?.uuidString.lowercased(),
            llmInteractionId: step.llmInteractionId?.uuidString.lowercased(),
            stepNumber: step.stepNumber,
            thoughtType: step.thoughtType.rawValue,
            content: step.content,
            evidenceUsed: mapEvidenceToRecord(step.evidenceUsed),
            confidence: step.confidence,
            tokensUsed: step.tokensUsed,
            executionTimeMs: step.executionTimeMs,
            createdAt: step.createdAt
        )
    }

    // MARK: - Performance Metrics

    public func toRecord(_ metrics: PRDPerformanceMetrics) -> SupabasePerformanceMetricsRecord {
        SupabasePerformanceMetricsRecord(
            id: metrics.id.uuidString.lowercased(),
            prdId: metrics.prdId.uuidString.lowercased(),
            qualityScore: metrics.qualityScore,
            completenessScore: metrics.completenessScore,
            clarityScore: metrics.clarityScore,
            technicalAccuracyScore: metrics.technicalAccuracyScore,
            totalGenerationTimeS: metrics.totalGenerationTimeSeconds,
            totalTokensUsed: metrics.totalTokensUsed,
            totalCostUsd: metrics.totalCostUsd,
            strategyUsed: metrics.strategyUsed,
            strategyEffectiveness: metrics.strategyEffectiveness,
            ragQueriesCount: metrics.ragQueriesCount,
            ragChunksUsed: metrics.ragChunksUsed,
            ragRelevanceAvg: metrics.ragRelevanceAvg,
            userSatisfactionScore: metrics.userSatisfactionScore,
            userWouldRecommend: metrics.userWouldRecommend,
            userFeedbackText: metrics.userFeedbackText,
            createdAt: metrics.createdAt,
            updatedAt: metrics.updatedAt
        )
    }

    // MARK: - Private Helpers

    private func mapParametersToRecord(_ params: LLMParameters) -> [String: AnyCodable]? {
        var dict: [String: AnyCodable] = [:]
        if let temp = params.temperature { dict["temperature"] = AnyCodable(temp) }
        if let max = params.maxTokens { dict["max_tokens"] = AnyCodable(max) }
        if let topP = params.topP { dict["top_p"] = AnyCodable(topP) }
        if let topK = params.topK { dict["top_k"] = AnyCodable(topK) }
        return dict.isEmpty ? nil : dict
    }

    private func mapParametersToDomain(_ params: [String: AnyCodable]?) -> LLMParameters {
        guard let params = params else { return LLMParameters() }
        return LLMParameters(
            temperature: params["temperature"]?.value as? Double,
            maxTokens: params["max_tokens"]?.value as? Int,
            topP: params["top_p"]?.value as? Double,
            topK: params["top_k"]?.value as? Int,
            stopSequences: nil
        )
    }

    private func mapCharacteristicsToRecord(_ chars: InputCharacteristics) -> [String: AnyCodable]? {
        var dict: [String: AnyCodable] = [:]
        if let c = chars.complexity { dict["complexity"] = AnyCodable(c) }
        if let a = chars.ambiguity { dict["ambiguity"] = AnyCodable(a) }
        if let d = chars.domain { dict["domain"] = AnyCodable(d) }
        if let h = chars.hasCodebase { dict["has_codebase"] = AnyCodable(h) }
        if let m = chars.hasMockups { dict["has_mockups"] = AnyCodable(m) }
        return dict.isEmpty ? nil : dict
    }

    private func mapPerformanceToRecord(_ perf: StrategyPerformance?) -> [String: AnyCodable]? {
        guard let perf = perf else { return nil }
        var dict: [String: AnyCodable] = [:]
        if let q = perf.qualityScore { dict["quality_score"] = AnyCodable(q) }
        if let e = perf.executionTimeSeconds { dict["execution_time_s"] = AnyCodable(e) }
        if let t = perf.tokensUsed { dict["tokens_used"] = AnyCodable(t) }
        return dict.isEmpty ? nil : dict
    }

    private func mapChunksToRecord(_ chunks: [RetrievedChunk]) -> [[String: AnyCodable]]? {
        guard !chunks.isEmpty else { return nil }
        return chunks.map { chunk in
            var dict: [String: AnyCodable] = [:]
            dict["chunk_id"] = AnyCodable(chunk.chunkId.uuidString.lowercased())
            dict["file_path"] = AnyCodable(chunk.filePath)
            dict["score"] = AnyCodable(chunk.score)
            dict["content"] = AnyCodable(chunk.content)
            if let startLine = chunk.startLine { dict["start_line"] = AnyCodable(startLine) }
            if let endLine = chunk.endLine { dict["end_line"] = AnyCodable(endLine) }
            if let metadata = chunk.metadata { dict["metadata"] = AnyCodable(metadata) }
            return dict
        }
    }

    private func mapPatternsToRecord(_ patterns: [DetectedUIPattern]) -> [[String: AnyCodable]]? {
        guard !patterns.isEmpty else { return nil }
        return patterns.map { pattern in
            [
                "type": AnyCodable(pattern.type),
                "pattern": AnyCodable(pattern.pattern),
                "confidence": AnyCodable(pattern.confidence)
            ]
        }
    }

    private func mapColorSchemeToRecord(_ scheme: ColorSchemeInfo?) -> [String: String]? {
        guard let scheme = scheme else { return nil }
        var dict: [String: String] = [:]
        if let p = scheme.primary { dict["primary"] = p }
        if let s = scheme.secondary { dict["secondary"] = s }
        if let a = scheme.accent { dict["accent"] = a }
        if let b = scheme.background { dict["background"] = b }
        return dict.isEmpty ? nil : dict
    }

    private func mapEvidenceToRecord(_ evidence: [EvidenceReference]) -> [[String: AnyCodable]]? {
        guard !evidence.isEmpty else { return nil }
        return evidence.map { ref in
            var dict: [String: AnyCodable] = [:]
            dict["type"] = AnyCodable(ref.type.rawValue)
            dict["id"] = AnyCodable(ref.id.uuidString.lowercased())
            if let r = ref.relevance { dict["relevance"] = AnyCodable(r) }
            return dict
        }
    }
}
