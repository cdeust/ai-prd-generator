import Foundation
import Domain

/// Tracks clarification questions and their effectiveness
/// Single Responsibility: Intelligence tracking for clarification effectiveness
struct ClarificationTrackingService: Sendable {
    private let intelligenceTracker: IntelligenceTrackerService

    init(intelligenceTracker: IntelligenceTrackerService) {
        self.intelligenceTracker = intelligenceTracker
    }

    /// Track scored questions with coherence metrics
    func trackQuestionsWithCoherence(_ scoredQuestions: [ScoredQuestion]) async {
        for scored in scoredQuestions {
            let wasAsked = scored.coherenceScore >= 0.9 && scored.effectivenessScore >= 0.8
            do {
                _ = try await intelligenceTracker.trackClarification(
                    prdId: nil, questionId: scored.question.id,
                    questionText: scored.question.question,
                    reasoningForAsking: scored.question.rationale,
                    gapAddressed: scored.question.category.value,
                    coherenceScore: scored.coherenceScore,
                    valueAddScore: scored.effectivenessScore,
                    wasAskedToUser: wasAsked
                )
            } catch {
                print("❌ [Coherence] Failed to track: \(error)")
            }
        }
    }

    /// Track questions without coherence scoring
    func trackQuestionsWithoutScoring(_ questions: [ClarificationQuestion<String, Int, String>]) async {
        print("📝 [PRDContext] Tracking \(questions.count) questions without coherence scoring")
        for question in questions {
            do {
                _ = try await intelligenceTracker.trackClarification(
                    prdId: nil,
                    questionId: question.id,
                    questionText: question.question,
                    reasoningForAsking: question.rationale,
                    gapAddressed: question.category.value,
                    coherenceScore: nil,
                    valueAddScore: nil,
                    wasAskedToUser: true
                )
                print("✅ [PRDContext] Tracked question: \(question.id)")
            } catch {
                print("❌ [PRDContext] Failed to track question \(question.id): \(error)")
            }
        }
    }

    /// Track effectiveness feedback for answered questions
    func trackRoundEffectiveness(answeredQuestionIds: [UUID]) async {
        print("📊 [PRDContext] Tracking effectiveness for \(answeredQuestionIds.count) answered questions")
        for questionId in answeredQuestionIds {
            do {
                let traces = try await intelligenceTracker.clarificationTracker.findAnsweredByQuestionIds([questionId])
                guard let trace = traces.first else {
                    print("⚠️ [PRDContext] No trace found for question: \(questionId)")
                    continue
                }

                try await intelligenceTracker.clarificationTracker.updateEffectiveness(
                    traceId: trace.id,
                    wasHelpful: true,
                    improvedQuality: true,
                    shouldAskAgainForSimilar: true
                )
                print("✅ [PRDContext] Tracked effectiveness for question: \(questionId)")
            } catch {
                print("❌ [PRDContext] Failed to track effectiveness for \(questionId): \(error)")
            }
        }
    }

    /// Load previously answered clarifications from DB
    func loadPreviousClarifications(questionIds: [UUID]) async -> [ClarificationQAPair] {
        guard !questionIds.isEmpty else {
            return []
        }

        do {
            let traces = try await intelligenceTracker.clarificationTracker.findAnsweredByQuestionIds(questionIds)
            let pairs = traces.compactMap { trace -> ClarificationQAPair? in
                guard let answer = trace.userAnswer else { return nil }
                return ClarificationQAPair(question: trace.questionText, answer: answer)
            }
            print("📂 [Session] Loaded \(pairs.count) previous clarifications from DB")
            return pairs
        } catch {
            print("⚠️ [Session] Failed to load previous clarifications: \(error)")
            return []
        }
    }
}
