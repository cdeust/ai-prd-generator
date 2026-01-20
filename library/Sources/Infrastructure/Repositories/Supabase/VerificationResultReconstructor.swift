import Foundation
import Domain

/// Reconstructs verification results from database records
/// Single Responsibility: Complex reconstruction of verification result graphs
final class VerificationResultReconstructor {
    private let databaseClient: SupabaseDatabasePort
    private let judgmentConsensusTable = "judgment_consensus"
    private let judgmentScoresTable = "judgment_scores"
    private let verificationQuestionsTable = "verification_questions"

    init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
    }

    func reconstruct(_ record: VerificationResultRecord) async throws -> CoVVerificationResult? {
        let consensusRecords = try await loadConsensusRecords(for: record.id)
        var consensusResults: [JudgmentConsensus] = []
        var allQuestions: [VerificationQuestion] = []

        for consensusRecord in consensusRecords {
            let scores = try await loadScores(for: consensusRecord.id)

            guard let consensus = try await buildConsensus(
                from: consensusRecord,
                scores: scores
            ) else {
                continue
            }

            if let question = try await loadQuestion(id: consensusRecord.verificationQuestionId) {
                allQuestions.append(question)
            }

            consensusResults.append(consensus)
        }

        return buildFinalResult(
            record: record,
            questions: allQuestions,
            consensusResults: consensusResults
        )
    }

    // MARK: - Private Loaders

    private func loadConsensusRecords(for verificationResultId: String) async throws -> [JudgmentConsensusRecord] {
        let filter = QueryFilter(
            field: "verification_result_id",
            operation: .equals,
            value: verificationResultId
        )
        let data = try await databaseClient.select(
            from: judgmentConsensusTable,
            columns: nil,
            filter: filter
        )
        return try decodeJudgmentConsensus(data)
    }

    private func loadScores(for consensusId: String) async throws -> [JudgmentScore] {
        let filter = QueryFilter(
            field: "judgment_consensus_id",
            operation: .equals,
            value: consensusId
        )
        let data = try await databaseClient.select(
            from: judgmentScoresTable,
            columns: nil,
            filter: filter
        )
        let records = try decodeJudgmentScores(data)

        return records.compactMap { record in
            guard let id = UUID(uuidString: record.id),
                  let questionId = UUID(uuidString: record.verificationQuestionId),
                  let timestamp = ISO8601DateFormatter().date(from: record.createdAt) else {
                return nil
            }

            return JudgmentScore(
                id: id,
                judgeProvider: record.judgeProvider,
                judgeModel: record.judgeModel,
                score: record.score,
                confidence: record.confidence,
                reasoning: record.reasoning,
                verificationQuestionId: questionId,
                timestamp: timestamp
            )
        }
    }

    private func loadQuestion(id: String) async throws -> VerificationQuestion? {
        let filter = QueryFilter(field: "id", operation: .equals, value: id.lowercased())
        let data = try await databaseClient.select(
            from: verificationQuestionsTable,
            columns: nil,
            filter: filter
        )

        guard let record = try decodeVerificationQuestions(data).first,
              let questionId = UUID(uuidString: id) else {
            return nil
        }

        return VerificationQuestion(
            id: questionId,
            question: record.questionText,
            category: VerificationCategory(rawValue: record.questionType) ?? .factualAccuracy,
            priority: Int(record.importanceWeight ?? 1.0),
            createdAt: ISO8601DateFormatter().date(from: record.createdAt) ?? Date()
        )
    }

    // MARK: - Private Builders

    private func buildConsensus(
        from record: JudgmentConsensusRecord,
        scores: [JudgmentScore]
    ) async throws -> JudgmentConsensus? {
        guard let consensusId = UUID(uuidString: record.id),
              let questionId = UUID(uuidString: record.verificationQuestionId),
              let agreementLevel = AgreementLevel(rawValue: record.agreementLevel),
              let timestamp = ISO8601DateFormatter().date(from: record.createdAt) else {
            return nil
        }

        return JudgmentConsensus(
            id: consensusId,
            verificationQuestionId: questionId,
            individualScores: scores,
            consensusScore: record.consensusScore,
            consensusConfidence: record.consensusConfidence,
            agreementLevel: agreementLevel,
            timestamp: timestamp
        )
    }

    private func buildFinalResult(
        record: VerificationResultRecord,
        questions: [VerificationQuestion],
        consensusResults: [JudgmentConsensus]
    ) -> CoVVerificationResult? {
        guard let id = UUID(uuidString: record.id),
              let timestamp = ISO8601DateFormatter().date(from: record.createdAt) else {
            return nil
        }

        let recommendations = decodeRecommendations(record.recommendationsJson) ?? []

        return CoVVerificationResult(
            id: id,
            originalResponse: record.originalResponse,
            verificationQuestions: questions,
            consensusResults: consensusResults,
            overallScore: record.overallScore,
            overallConfidence: record.overallConfidence,
            verified: record.verified,
            recommendations: recommendations,
            timestamp: timestamp
        )
    }

    // MARK: - Private Decoding

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

    private func decodeRecommendations(_ json: String?) -> [String]? {
        guard let json = json,
              let data = json.data(using: .utf8),
              let recommendations = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        return recommendations
    }
}
