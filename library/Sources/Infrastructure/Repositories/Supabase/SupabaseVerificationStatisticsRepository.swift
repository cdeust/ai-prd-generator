import Foundation
import Domain

/// Repository for verification statistics and analytics queries
/// Single Responsibility: Query aggregated verification metrics
final class SupabaseVerificationStatisticsRepository {
    private let databaseClient: SupabaseDatabasePort
    private let verificationResultsTable = "verification_results"
    private let verificationQuestionsTable = "verification_questions"
    private let judgmentScoresTable = "judgment_scores"

    init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
    }

    func getVerificationStatistics(
        for verificationType: VerificationType,
        since: Date
    ) async throws -> VerificationStatistics {
        let isoFormatter = ISO8601DateFormatter()
        let filter = QueryFilter(field: "verification_type", operation: .equals, value: verificationType.rawValue)
        let data = try await databaseClient.select(from: verificationResultsTable, columns: nil, filter: filter)

        let records = try decodeVerificationResults(data)
            .filter { record in
                guard let createdAt = isoFormatter.date(from: record.createdAt) else {
                    return false
                }
                return createdAt >= since
            }

        guard !records.isEmpty else {
            return VerificationStatistics(
                verificationType: verificationType,
                totalVerifications: 0,
                averageScore: 0.5,
                averageConfidence: 0.5,
                verificationRate: 0.0
            )
        }

        let totalVerifications = records.count
        let averageScore = records.map(\.overallScore).reduce(0, +) / Double(totalVerifications)
        let averageConfidence = records.map(\.overallConfidence).reduce(0, +) / Double(totalVerifications)
        let verifiedCount = records.filter { $0.verified }.count
        let verificationRate = Double(verifiedCount) / Double(totalVerifications)

        return VerificationStatistics(
            verificationType: verificationType,
            totalVerifications: totalVerifications,
            averageScore: averageScore,
            averageConfidence: averageConfidence,
            verificationRate: verificationRate
        )
    }

    func getJudgePerformance(
        provider: String?,
        model: String?
    ) async throws -> [JudgePerformanceMetrics] {
        let data = try await databaseClient.select(from: judgmentScoresTable, columns: nil, filter: nil)
        var scores = try decodeJudgmentScores(data)

        if let provider = provider {
            scores = scores.filter { $0.judgeProvider == provider }
        }
        if let model = model {
            scores = scores.filter { $0.judgeModel == model }
        }

        var judgeGroups: [String: [JudgmentScoreRecord]] = [:]
        for score in scores {
            let key = "\(score.judgeProvider)/\(score.judgeModel)"
            judgeGroups[key, default: []].append(score)
        }

        return judgeGroups.compactMap { _, scores in
            guard let firstScore = scores.first else { return nil }

            let totalEvaluations = scores.count
            let avgScore = scores.map(\.score).reduce(0, +) / Double(totalEvaluations)
            let avgConfidence = scores.map(\.confidence).reduce(0, +) / Double(totalEvaluations)
            let avgDeviation = scores.compactMap(\.deviationFromConsensus).reduce(0, +) / Double(scores.count)
            let reliabilityScore = max(0.0, 1.0 - avgDeviation)

            return JudgePerformanceMetrics(
                judgeProvider: firstScore.judgeProvider,
                judgeModel: firstScore.judgeModel,
                totalEvaluations: totalEvaluations,
                averageScore: avgScore,
                averageConfidence: avgConfidence,
                averageDeviation: avgDeviation,
                reliabilityScore: reliabilityScore
            )
        }
    }

    func getOptimalQuestions(
        for verificationType: VerificationType,
        limit: Int
    ) async throws -> [VerificationQuestion] {
        let data = try await databaseClient.select(from: verificationQuestionsTable, columns: nil, filter: nil)
        let records = try decodeVerificationQuestions(data)

        let sorted = records
            .filter { ($0.timesUsed ?? 0) > 0 }
            .sorted { lhs, rhs in
                let lhsEffectiveness = Double(lhs.timesUsed ?? 0) * (lhs.averageConsensusScore ?? 0.5)
                let rhsEffectiveness = Double(rhs.timesUsed ?? 0) * (rhs.averageConsensusScore ?? 0.5)
                return lhsEffectiveness > rhsEffectiveness
            }
            .prefix(limit)

        return sorted.map { record in
            VerificationQuestion(
                id: UUID(uuidString: record.id) ?? UUID(),
                question: record.questionText,
                category: VerificationCategory(rawValue: record.questionType) ?? .factualAccuracy,
                priority: Int(record.importanceWeight ?? 1.0),
                createdAt: ISO8601DateFormatter().date(from: record.createdAt) ?? Date()
            )
        }
    }

    func getRefinementEffectiveness(
        for entityType: VerificationEntityType
    ) async throws -> RefinementEffectivenessMetrics {
        let filter = QueryFilter(field: "entity_type", operation: .equals, value: entityType.rawValue)
        let data = try await databaseClient.select(from: verificationResultsTable, columns: nil, filter: filter)
        let records = try decodeVerificationResults(data)

        var attemptGroups: [Int: [VerificationResultRecord]] = [:]
        for record in records {
            attemptGroups[record.refinementAttempt, default: []].append(record)
        }

        var refinementsByAttempt: [Int: RefinementAttemptMetrics] = [:]
        for (attempt, records) in attemptGroups {
            let totalAttempts = records.count
            let avgScore = records.map(\.overallScore).reduce(0, +) / Double(totalAttempts)
            let verifiedCount = records.filter(\.verified).count
            let successRate = Double(verifiedCount) / Double(totalAttempts)

            refinementsByAttempt[attempt] = RefinementAttemptMetrics(
                attemptNumber: attempt,
                totalAttempts: totalAttempts,
                averageScore: avgScore,
                successRate: successRate
            )
        }

        let totalRefinements = records.filter { $0.refinementAttempt > 0 }.count
        let avgScoreImprovement = 0.0
        let successRate = refinementsByAttempt.values
            .map(\.successRate)
            .reduce(0, +) / Double(max(1, refinementsByAttempt.count))

        return RefinementEffectivenessMetrics(
            entityType: entityType,
            totalRefinements: totalRefinements,
            averageScoreImprovement: avgScoreImprovement,
            successRate: successRate,
            refinementsByAttempt: refinementsByAttempt
        )
    }

    // MARK: - Private Decoding

    private func decodeVerificationResults(_ data: Data) throws -> [VerificationResultRecord] {
        let decoder = createDecoder()
        return try decoder.decode([VerificationResultRecord].self, from: data)
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
}
