import Foundation
import Domain

/// Supabase implementation of verification evidence repository
/// Single Responsibility: Verification evidence persistence via Supabase
/// Enables meta-learning through storing and querying verification history
public final class SupabaseVerificationEvidenceRepository: VerificationEvidenceRepositoryPort {
    private let databaseClient: SupabaseDatabasePort
    private let reconstructor: VerificationResultReconstructor
    private let statisticsRepository: SupabaseVerificationStatisticsRepository

    // Table names
    private let verificationResultsTable = "verification_results"
    private let verificationQuestionsTable = "verification_questions"
    private let judgmentConsensusTable = "judgment_consensus"
    private let judgmentScoresTable = "judgment_scores"

    public init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
        self.reconstructor = VerificationResultReconstructor(databaseClient: databaseClient)
        self.statisticsRepository = SupabaseVerificationStatisticsRepository(databaseClient: databaseClient)
    }

    public func saveVerification(
        _ result: CoVVerificationResult,
        entityType: VerificationEntityType,
        entityId: UUID,
        verificationType: VerificationType
    ) async throws -> UUID {
        // Step 1: Save or reuse verification questions
        var questionIdMap: [UUID: UUID] = [:]
        for vq in result.verificationQuestions {
            let dbQuestionId = try await saveOrReuseQuestion(vq)
            questionIdMap[vq.id] = dbQuestionId
        }

        // Step 2: Save verification result
        let verificationId = try await saveVerificationResult(
            result,
            entityType: entityType,
            entityId: entityId,
            verificationType: verificationType
        )

        // Step 3: Save consensus and scores
        for consensus in result.consensusResults {
            guard let dbQuestionId = questionIdMap[consensus.verificationQuestionId] else {
                continue
            }

            let consensusId = try await saveJudgmentConsensus(
                consensus,
                verificationResultId: verificationId,
                questionId: dbQuestionId
            )

            // Step 4: Save individual judge scores
            for score in consensus.individualScores {
                try await saveJudgmentScore(
                    score,
                    consensusId: consensusId,
                    questionId: dbQuestionId,
                    consensusScore: consensus.consensusScore
                )
            }
        }

        return verificationId
    }

    public func findVerificationById(_ id: UUID) async throws -> CoVVerificationResult? {
        let filter = QueryFilter(field: "id", operation: .equals, value: id.uuidString.lowercased())
        let data = try await databaseClient.select(from: verificationResultsTable, columns: nil, filter: filter)

        guard let record = try decodeVerificationResults(data).first else {
            return nil
        }

        return try await reconstructVerificationResult(record)
    }

    public func findVerificationsForEntity(
        type: VerificationEntityType,
        entityId: UUID
    ) async throws -> [CoVVerificationResult] {
        let filter = QueryFilter(field: "entity_type", operation: .equals, value: type.rawValue)
        let data = try await databaseClient.select(from: verificationResultsTable, columns: nil, filter: filter)

        let isoFormatter = ISO8601DateFormatter()
        let records = try decodeVerificationResults(data)
            .filter { $0.entityId.lowercased() == entityId.uuidString.lowercased() }
            .sorted { lhs, rhs in
                let lhsDate = isoFormatter.date(from: lhs.createdAt) ?? Date.distantPast
                let rhsDate = isoFormatter.date(from: rhs.createdAt) ?? Date.distantPast
                return lhsDate > rhsDate
            }

        var results: [CoVVerificationResult] = []
        for record in records {
            if let result = try await reconstructVerificationResult(record) {
                results.append(result)
            }
        }

        return results
    }

    public func findLatestVerification(
        for entityType: VerificationEntityType,
        entityId: UUID
    ) async throws -> CoVVerificationResult? {
        let verifications = try await findVerificationsForEntity(type: entityType, entityId: entityId)
        return verifications.first
    }

    public func getVerificationStatistics(
        for verificationType: VerificationType,
        since: Date
    ) async throws -> VerificationStatistics {
        return try await statisticsRepository.getVerificationStatistics(for: verificationType, since: since)
    }

    public func getJudgePerformance(
        provider: String?,
        model: String?
    ) async throws -> [JudgePerformanceMetrics] {
        return try await statisticsRepository.getJudgePerformance(provider: provider, model: model)
    }

    public func getOptimalQuestions(
        for verificationType: VerificationType,
        limit: Int
    ) async throws -> [VerificationQuestion] {
        return try await statisticsRepository.getOptimalQuestions(for: verificationType, limit: limit)
    }

    public func getRefinementEffectiveness(
        for entityType: VerificationEntityType
    ) async throws -> RefinementEffectivenessMetrics {
        return try await statisticsRepository.getRefinementEffectiveness(for: entityType)
    }

    // MARK: - Private Save Methods

    private func saveOrReuseQuestion(_ question: VerificationQuestion) async throws -> UUID {
        // Check if question already exists (by text similarity)
        let data = try await databaseClient.select(from: verificationQuestionsTable, columns: nil, filter: nil)
        let existing = try decodeVerificationQuestions(data)
            .first { $0.questionText == question.question }

        if let existing = existing, let existingId = UUID(uuidString: existing.id) {
            // Update usage count
            return existingId
        }

        // Insert new question
        let record = VerificationQuestionRecord(
            id: question.id.uuidString.lowercased(),
            questionText: question.question,
            questionType: question.category.rawValue,
            importanceWeight: Double(question.priority),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            timesUsed: 1,
            averageConsensusScore: nil,
            averageJudgeAgreement: nil
        )

        let responseData = try await databaseClient.insert(table: verificationQuestionsTable, values: record)
        let inserted = try decodeVerificationQuestions(responseData)

        guard let first = inserted.first, let id = UUID(uuidString: first.id) else {
            return question.id
        }

        return id
    }

    private func saveVerificationResult(
        _ result: CoVVerificationResult,
        entityType: VerificationEntityType,
        entityId: UUID,
        verificationType: VerificationType
    ) async throws -> UUID {
        let isoFormatter = ISO8601DateFormatter()

        let record = VerificationResultRecord(
            id: result.id.uuidString.lowercased(),
            entityType: entityType.rawValue,
            entityId: entityId.uuidString.lowercased(),
            originalResponse: result.originalResponse,
            overallScore: result.overallScore,
            overallConfidence: result.overallConfidence,
            verified: result.verified,
            verificationType: verificationType.rawValue,
            refinementAttempt: 0,
            recommendationsJson: try? encodeRecommendations(result.recommendations),
            createdAt: isoFormatter.string(from: result.timestamp),
            prdDocumentId: entityType == .prdDocument ? entityId.uuidString.lowercased() : nil,
            clarificationSessionId: entityType == .clarificationSession ? entityId.uuidString.lowercased() : nil
        )

        _ = try await databaseClient.insert(table: verificationResultsTable, values: record)
        return result.id
    }

    private func saveJudgmentConsensus(
        _ consensus: JudgmentConsensus,
        verificationResultId: UUID,
        questionId: UUID
    ) async throws -> UUID {
        let isoFormatter = ISO8601DateFormatter()

        let record = JudgmentConsensusRecord(
            id: consensus.id.uuidString.lowercased(),
            verificationResultId: verificationResultId.uuidString.lowercased(),
            verificationQuestionId: questionId.uuidString.lowercased(),
            consensusScore: consensus.consensusScore,
            consensusConfidence: consensus.consensusConfidence,
            agreementLevel: consensus.agreementLevel.rawValue,
            scoreVariance: consensus.scoreVariance,
            createdAt: isoFormatter.string(from: consensus.timestamp)
        )

        _ = try await databaseClient.insert(table: judgmentConsensusTable, values: record)
        return consensus.id
    }

    private func saveJudgmentScore(
        _ score: JudgmentScore,
        consensusId: UUID,
        questionId: UUID,
        consensusScore: Double
    ) async throws {
        let isoFormatter = ISO8601DateFormatter()

        let deviation = abs(score.score - consensusScore)

        let record = JudgmentScoreRecord(
            id: score.id.uuidString.lowercased(),
            judgmentConsensusId: consensusId.uuidString.lowercased(),
            verificationQuestionId: questionId.uuidString.lowercased(),
            judgeProvider: score.judgeProvider,
            judgeModel: score.judgeModel,
            score: score.score,
            confidence: score.confidence,
            reasoning: score.reasoning,
            weightedScore: score.weightedScore,
            deviationFromConsensus: deviation,
            createdAt: isoFormatter.string(from: score.timestamp)
        )

        _ = try await databaseClient.insert(table: judgmentScoresTable, values: record)
    }

    // MARK: - Private Reconstruction Methods

    private func reconstructVerificationResult(_ record: VerificationResultRecord) async throws -> CoVVerificationResult? {
        return try await reconstructor.reconstruct(record)
    }

    // MARK: - Private Decoding Methods

    private func decodeVerificationResults(_ data: Data) throws -> [VerificationResultRecord] {
        let decoder = createDecoder()
        return try decoder.decode([VerificationResultRecord].self, from: data)
    }

    private func decodeJudgmentConsensus(_ data: Data) throws -> [JudgmentConsensusRecord] {
        let decoder = createDecoder()
        return try decoder.decode([JudgmentConsensusRecord].self, from: data)
    }

    private func decodeJudgmentScores(_ data: Data) throws -> [JudgmentScoreRecord] {
        let decoder = createDecoder()
        return try decoder.decode([JudgmentScoreRecord].self, from: data)
    }

    private func decodeVerificationQuestions(_ data: Data) throws -> [VerificationQuestionRecord] {
        let decoder = createDecoder()
        return try decoder.decode([VerificationQuestionRecord].self, from: data)
    }

    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    private func encodeRecommendations(_ recommendations: [String]) throws -> String {
        let data = try JSONEncoder().encode(recommendations)
        return String(data: data, encoding: .utf8) ?? "[]"
    }
    private func decodeRecommendations(_ json: String?) -> [String]? {
        guard let json = json,
              let data = json.data(using: .utf8),
              let recommendations = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return recommendations
    }
}