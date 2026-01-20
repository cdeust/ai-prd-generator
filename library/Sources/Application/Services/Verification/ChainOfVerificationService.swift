import Foundation
import Domain

/// Service to orchestrate full Chain of Verification (CoV) process
/// Implements 4-step CoV pattern with multi-judge consensus
/// Following Single Responsibility: Orchestrates verification flow
public actor ChainOfVerificationService {
    private let questionGenerator: VerificationQuestionGeneratorService
    private let judgeEvaluator: MultiJudgeEvaluationService
    private let consensusResolver: ConsensusResolverService

    public init(
        questionGenerator: VerificationQuestionGeneratorService,
        judgeEvaluator: MultiJudgeEvaluationService,
        consensusResolver: ConsensusResolverService
    ) {
        self.questionGenerator = questionGenerator
        self.judgeEvaluator = judgeEvaluator
        self.consensusResolver = consensusResolver
    }

    /// Execute full Chain of Verification (4 steps)
    /// 1. Draft initial response (provided as input)
    /// 2. Plan verification questions
    /// 3. Answer questions independently (multiple judges)
    /// 4. Generate final verified response
    /// - Parameters:
    ///   - originalRequest: Original user request
    ///   - response: Response to verify (Step 1 - already completed)
    ///   - verificationThreshold: Minimum score to pass verification (0.0-1.0)
    /// - Returns: Verification result with consensus and recommendations
    /// - Throws: AIProviderError if verification fails
    public func verify(
        originalRequest: String,
        response: String,
        verificationThreshold: Double = 0.75,
        entityType: VerificationEntityType? = nil,
        entityId: UUID? = nil,
        verificationType: VerificationType = .prdQuality
    ) async throws -> CoVVerificationResult {
        let questions = try await questionGenerator.generateQuestions(
            originalRequest: originalRequest,
            response: response,
            maxQuestions: 5
        )
        let consensusResults = try await evaluateQuestionsWithConsensus(
            questions: questions,
            originalRequest: originalRequest,
            response: response
        )
        let scores = calculateVerificationScores(
            consensusResults: consensusResults,
            questions: questions,
            verificationThreshold: verificationThreshold
        )

        return CoVVerificationResult(
            originalResponse: response,
            verificationQuestions: questions,
            consensusResults: consensusResults,
            overallScore: scores.overallScore,
            overallConfidence: scores.overallConfidence,
            verified: scores.verified,
            recommendations: scores.recommendations
        )
    }

    private func evaluateQuestionsWithConsensus(
        questions: [VerificationQuestion],
        originalRequest: String,
        response: String
    ) async throws -> [JudgmentConsensus] {
        var consensusResults: [JudgmentConsensus] = []
        for question in questions {
            let scores = try await judgeEvaluator.evaluateWithJudges(
                question: question,
                originalRequest: originalRequest,
                response: response
            )
            let consensus = consensusResolver.resolveConsensus(
                scores: scores,
                verificationQuestionId: question.id
            )
            consensusResults.append(consensus)
        }
        return consensusResults
    }

    private struct VerificationScores {
        let overallScore: Double
        let overallConfidence: Double
        let verified: Bool
        let recommendations: [String]
    }

    private func calculateVerificationScores(
        consensusResults: [JudgmentConsensus],
        questions: [VerificationQuestion],
        verificationThreshold: Double
    ) -> VerificationScores {
        let overallScore = calculateOverallScore(consensusResults)
        let overallConfidence = calculateOverallConfidence(consensusResults)
        let verified = overallScore >= verificationThreshold
        let recommendations = generateRecommendations(
            consensusResults: consensusResults,
            questions: questions,
            verified: verified
        )
        return VerificationScores(
            overallScore: overallScore,
            overallConfidence: overallConfidence,
            verified: verified,
            recommendations: recommendations
        )
    }

    private func calculateOverallScore(_ consensusResults: [JudgmentConsensus]) -> Double {
        guard !consensusResults.isEmpty else { return 0.0 }

        return consensusResults
            .map(\.consensusScore)
            .reduce(0, +) / Double(consensusResults.count)
    }

    private func calculateOverallConfidence(_ consensusResults: [JudgmentConsensus]) -> Double {
        guard !consensusResults.isEmpty else { return 0.0 }

        return consensusResults
            .map(\.consensusConfidence)
            .reduce(0, +) / Double(consensusResults.count)
    }

    private func generateRecommendations(
        consensusResults: [JudgmentConsensus],
        questions: [VerificationQuestion],
        verified: Bool
    ) -> [String] {
        var recommendations: [String] = []

        if !verified {
            recommendations.append(
                "Response failed verification. Consider revising based on low-scoring areas."
            )
        }

        let lowScoreConsensus = consensusResults.filter { $0.consensusScore < 0.6 }
        for consensus in lowScoreConsensus {
            if let question = questions.first(where: { $0.id == consensus.verificationQuestionId }) {
                recommendations.append(
                    "Low score on \(question.category.rawValue): \(question.question)"
                )
            }
        }

        let lowAgreementConsensus = consensusResults.filter { $0.agreementLevel == .low }
        if !lowAgreementConsensus.isEmpty {
            recommendations.append(
                "Judges disagree on \(lowAgreementConsensus.count) question(s). Consider manual review."
            )
        }

        if recommendations.isEmpty && verified {
            recommendations.append("Response passed all verification checks with high confidence.")
        }

        return recommendations
    }
}
