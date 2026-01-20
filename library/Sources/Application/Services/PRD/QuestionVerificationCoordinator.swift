import Foundation
import Domain

/// Coordinates verification of clarification questions using Chain of Verification
/// Single Responsibility: Multi-judge verification of question quality
struct QuestionVerificationCoordinator: Sendable {
    private let verificationService: ChainOfVerificationService

    init(verificationService: ChainOfVerificationService) {
        self.verificationService = verificationService
    }

    /// Verify questions with multiple AI judges using Chain of Verification
    func verifyQuestions(
        _ questions: [ClarificationQuestion<String, Int, String>],
        request: PRDRequest
    ) async throws -> [ClarificationQuestion<String, Int, String>] {
        print("🔍 [Verification] Starting verification of \(questions.count) questions with multiple judges...")

        let questionsText = formatQuestionsForVerification(questions)

        let verificationResult: CoVVerificationResult
        do {
            verificationResult = try await verificationService.verify(
                originalRequest: request.description,
                response: questionsText,
                verificationThreshold: VerificationThresholds.questionVerification,
                entityType: .clarificationSession,
                entityId: nil,
                verificationType: .questionRelevance
            )
            print("📊 [Verification] Overall score: \(verificationResult.overallScore) (threshold: \(VerificationThresholds.questionVerification))")
        } catch {
            print("❌ [Verification] Failed to verify questions: \(error)")
            print("⚠️ [Verification] Proceeding without verification (asking all questions)")
            return questions
        }

        return filterByConsensus(questions: questions, verificationResult: verificationResult)
    }

    private func formatQuestionsForVerification(
        _ questions: [ClarificationQuestion<String, Int, String>]
    ) -> String {
        questions
            .sorted { $0.priority > $1.priority }
            .map { "- [\($0.category.value)] \($0.question)" }
            .joined(separator: "\n")
    }

    private func filterByConsensus(
        questions: [ClarificationQuestion<String, Int, String>],
        verificationResult: CoVVerificationResult
    ) -> [ClarificationQuestion<String, Int, String>] {
        if verificationResult.verified {
            print("✅ [Verification] Questions verified - keeping all \(questions.count) questions")
            return questions
        }

        let consensusThreshold = 0.7
        let consensusMap = Dictionary(uniqueKeysWithValues:
            verificationResult.consensusResults.map { ($0.verificationQuestionId, $0) }
        )

        let filteredQuestions = questions.filter { question in
            if let consensus = consensusMap[question.id] {
                return consensus.consensusScore >= consensusThreshold
            }
            return true
        }

        print("⚠️ [Verification] Questions failed overall verification")
        print("🎯 [Verification] Kept \(filteredQuestions.count)/\(questions.count) based on consensus")
        return filteredQuestions
    }
}
