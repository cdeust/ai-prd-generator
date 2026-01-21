import Foundation
import Domain

/// Scores clarification questions for coherence and effectiveness before asking
/// - Coherence: Is this question relevant to the product being built? (threshold: 0.9)
/// - Effectiveness: Measured against feature description - will this help? (threshold: 0.8)
/// Questions below thresholds are filtered out and NEVER asked to user
public struct QuestionCoherenceScorer: Sendable {
    private let aiProvider: AIProviderPort
    private let coherenceThreshold: Double
    private let effectivenessThreshold: Double
    private let promptBuilder: CoherenceScoringPromptBuilder
    private let scoreParser: CoherenceScoreParser
    private let verifier: LLMResponseVerifier?

    public init(
        aiProvider: AIProviderPort,
        coherenceThreshold: Double = VerificationThresholds.preFilterCoherence,
        effectivenessThreshold: Double = VerificationThresholds.preFilterEffectiveness,
        verifier: LLMResponseVerifier? = nil
    ) {
        self.aiProvider = aiProvider
        self.coherenceThreshold = coherenceThreshold
        self.effectivenessThreshold = effectivenessThreshold
        self.promptBuilder = CoherenceScoringPromptBuilder()
        self.scoreParser = CoherenceScoreParser()
        self.verifier = verifier
    }

    /// Score ALL questions and return them with their coherence scores (no filtering)
    /// Uses multi-pass: scores ONE question at a time to avoid context window overflow
    public func scoreAllQuestions(
        questions: [ClarificationQuestion<String, Int, String>],
        request: PRDRequest,
        codebaseContext: RAGSearchResults?,
        mockupSummaries: [String]
    ) async throws -> [ScoredQuestion] {
        guard !questions.isEmpty else { return [] }

        // Multi-pass: Score ONE question at a time to stay within context limits
        var scoredQuestions: [ScoredQuestion] = []

        for (index, question) in questions.enumerated() {
            print("🔄 [CoherenceScorer] Scoring question \(index + 1)/\(questions.count)...")

            let prompt = promptBuilder.buildSingleQuestionPrompt(
                question: question,
                request: request,
                codebaseContext: codebaseContext,
                mockupSummaries: mockupSummaries
            )

            do {
                let response = try await aiProvider.generateText(prompt: prompt, temperature: 0.1)

                // Apply Chain of Verification to coherence scoring
                if let verifier = verifier {
                    let context = "Coherence scoring for clarification question: \(question.question)"
                    let verificationResult = try await verifier.verifyResponse(
                        prompt: prompt,
                        response: response,
                        context: context,
                        verificationType: .questionRelevance
                    )

                    if !verificationResult.verified {
                        print("⚠️ [QuestionCoherenceScorer] Scoring verification failed - using response with caution")
                    }
                }

                let scores = scoreParser.parseScores(from: response, questionCount: 1)
                let score = scores.first ?? QuestionScore(
                    coherence: 0.5,
                    effectiveness: 0.5,
                    reasoning: "Unable to score"
                )

                scoredQuestions.append(ScoredQuestion(
                    question: question,
                    coherenceScore: score.coherence,
                    effectivenessScore: score.effectiveness,
                    reasoning: score.reasoning
                ))
            } catch {
                print("⚠️ [CoherenceScorer] Failed to score question \(index + 1): \(error)")
                // Default to low score on failure - question won't pass thresholds
                scoredQuestions.append(ScoredQuestion(
                    question: question,
                    coherenceScore: 0.3,
                    effectivenessScore: 0.3,
                    reasoning: "Scoring failed: \(error.localizedDescription)"
                ))
            }
        }

        print("✅ [CoherenceScorer] Scored \(scoredQuestions.count) questions (multi-pass)")
        return scoredQuestions.sorted { $0.overallScore > $1.overallScore }
    }

    /// Score and filter questions based on coherence AND effectiveness
    public func filterCoherentQuestions(
        questions: [ClarificationQuestion<String, Int, String>],
        request: PRDRequest,
        codebaseContext: RAGSearchResults?,
        mockupSummaries: [String]
    ) async throws -> [ScoredQuestion] {
        let allScored = try await scoreAllQuestions(
            questions: questions, request: request,
            codebaseContext: codebaseContext, mockupSummaries: mockupSummaries
        )

        let filtered = allScored.filter { scored in
            scored.coherenceScore >= coherenceThreshold && scored.effectivenessScore >= effectivenessThreshold
        }
        print("✅ [Scorer] Kept \(filtered.count)/\(allScored.count)")
        return filtered
    }

    private func mapToScoredQuestions(
        questions: [ClarificationQuestion<String, Int, String>],
        scores: [QuestionScore]
    ) -> [ScoredQuestion] {
        questions.enumerated().map { index, question in
            let score = index < scores.count
                ? scores[index]
                : QuestionScore(coherence: 0.5, effectiveness: 0.5, reasoning: "Unable to score")
            return ScoredQuestion(
                question: question,
                coherenceScore: score.coherence,
                effectivenessScore: score.effectiveness,
                reasoning: score.reasoning
            )
        }
    }
}
