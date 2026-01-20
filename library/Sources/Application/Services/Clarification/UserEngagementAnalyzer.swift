import Foundation

/// Analyzes user engagement patterns from clarification responses
/// Single Responsibility: Evaluate user response quality and adapt questioning strategy
struct UserEngagementAnalyzer: Sendable {
    /// Analyze the quality and detail level of user's previous answers
    func analyzeUserResponseQuality(_ clarifications: [(question: String, answer: String)]) -> String {
        guard !clarifications.isEmpty else { return "" }

        let avgAnswerLength = clarifications.map { $0.answer.count }.reduce(0, +) / clarifications.count
        let detailedAnswers = clarifications.filter { $0.answer.count > 100 }.count
        let briefAnswers = clarifications.filter { $0.answer.count < 30 }.count

        let engagementLevel: String
        if detailedAnswers > clarifications.count / 2 {
            engagementLevel = "HIGH_DETAIL"
        } else if briefAnswers > clarifications.count / 2 {
            engagementLevel = "BRIEF"
        } else {
            engagementLevel = "MODERATE"
        }

        return """
        User has answered \(clarifications.count) question(s) so far.
        Average answer length: \(avgAnswerLength) characters
        Detailed answers: \(detailedAnswers), Brief answers: \(briefAnswers)
        Engagement level: \(engagementLevel)
        """
    }

    /// Generate adaptation guidance based on user response patterns
    func generateAdaptationGuidance(_ clarifications: [(question: String, answer: String)]) -> String {
        guard !clarifications.isEmpty else { return "Ask clear, specific questions." }

        let avgLength = clarifications.map { $0.answer.count }.reduce(0, +) / clarifications.count
        let briefCount = clarifications.filter { $0.answer.count < 30 }.count

        if briefCount > clarifications.count / 2 {
            return """
            User provides BRIEF answers. Strategy:
            - Ask ONLY 1-2 most critical questions (not 5)
            - Make questions VERY specific with clear binary choices
            - Provide detailed examples to guide the user
            - Front-load all context in the question itself
            """
        } else if avgLength > 150 {
            return """
            User provides DETAILED answers. Strategy:
            - You can ask 2-4 questions
            - Questions can be slightly broader as user will elaborate
            - Still provide examples but user demonstrates they understand context
            """
        } else {
            return """
            User provides MODERATE answers. Strategy:
            - Ask 2-3 focused questions
            - Balance specificity with allowing some user elaboration
            - Provide clear examples to guide response format
            """
        }
    }
}
