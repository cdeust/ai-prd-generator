import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import AIPRDVerificationEngine
import XCTest
@testable import Application
@testable import Domain

final class ConsensusResolverServiceTests: XCTestCase {
    private var sut: ConsensusResolverService!

    override func setUp() async throws {
        try await super.setUp()
        sut = ConsensusResolverService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func testResolveConsensus_WithHighAgreement_ReturnsHighAgreementLevel() {
        let questionId = UUID()
        let scores = [
            JudgmentScore(
                judgeProvider: "openai",
                judgeModel: "gpt-4o",
                score: 0.85,
                confidence: 0.90,
                reasoning: "Good quality",
                verificationQuestionId: questionId
            ),
            JudgmentScore(
                judgeProvider: "anthropic",
                judgeModel: "claude-sonnet-4-5",
                score: 0.87,
                confidence: 0.92,
                reasoning: "Very good quality",
                verificationQuestionId: questionId
            ),
            JudgmentScore(
                judgeProvider: "gemini",
                judgeModel: "gemini-2.5-pro",
                score: 0.86,
                confidence: 0.88,
                reasoning: "High quality",
                verificationQuestionId: questionId
            )
        ]

        let consensus = sut.resolveConsensus(
            scores: scores,
            verificationQuestionId: questionId
        )

        XCTAssertEqual(consensus.agreementLevel, .high)
        XCTAssertGreaterThan(consensus.consensusScore, 0.8)
        XCTAssertGreaterThan(consensus.consensusConfidence, 0.8)
    }

    func testResolveConsensus_WithLowAgreement_ReturnsLowAgreementLevel() {
        let questionId = UUID()
        let scores = [
            JudgmentScore(
                judgeProvider: "openai",
                judgeModel: "gpt-4o",
                score: 0.2,
                confidence: 0.70,
                reasoning: "Poor quality",
                verificationQuestionId: questionId
            ),
            JudgmentScore(
                judgeProvider: "anthropic",
                judgeModel: "claude-sonnet-4-5",
                score: 0.9,
                confidence: 0.85,
                reasoning: "Excellent quality",
                verificationQuestionId: questionId
            ),
            JudgmentScore(
                judgeProvider: "gemini",
                judgeModel: "gemini-2.5-pro",
                score: 0.5,
                confidence: 0.60,
                reasoning: "Mediocre quality",
                verificationQuestionId: questionId
            )
        ]

        let consensus = sut.resolveConsensus(
            scores: scores,
            verificationQuestionId: questionId
        )

        XCTAssertEqual(consensus.agreementLevel, .low)
    }

    func testResolveConsensus_WithEmptyScores_ReturnsZeroConsensus() {
        let questionId = UUID()
        let scores: [JudgmentScore] = []

        let consensus = sut.resolveConsensus(
            scores: scores,
            verificationQuestionId: questionId
        )

        XCTAssertEqual(consensus.consensusScore, 0.0)
        XCTAssertEqual(consensus.consensusConfidence, 0.0)
        XCTAssertEqual(consensus.agreementLevel, .low)
    }

    func testResolveConsensus_WeightedByConfidence_PrioritizesHighConfidenceScores() {
        let questionId = UUID()
        let scores = [
            JudgmentScore(
                judgeProvider: "openai",
                judgeModel: "gpt-4o",
                score: 0.5,
                confidence: 0.3,
                reasoning: "Uncertain",
                verificationQuestionId: questionId
            ),
            JudgmentScore(
                judgeProvider: "anthropic",
                judgeModel: "claude-sonnet-4-5",
                score: 0.9,
                confidence: 0.95,
                reasoning: "Very confident",
                verificationQuestionId: questionId
            )
        ]

        let consensus = sut.resolveConsensus(
            scores: scores,
            verificationQuestionId: questionId
        )

        XCTAssertGreaterThan(consensus.consensusScore, 0.7)
    }
}
