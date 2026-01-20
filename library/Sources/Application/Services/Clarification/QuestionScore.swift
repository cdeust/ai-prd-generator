import Foundation

/// Internal score structure for parsing LLM responses
/// Contains raw coherence and effectiveness scores before mapping to ScoredQuestion
struct QuestionScore: Sendable {
    let coherence: Double
    let effectiveness: Double
    let reasoning: String

    init(coherence: Double, effectiveness: Double, reasoning: String) {
        self.coherence = coherence
        self.effectiveness = effectiveness
        self.reasoning = reasoning
    }
}
