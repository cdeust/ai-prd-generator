import Foundation
import Domain

/// Formatting utilities for clarification verification
/// Single Responsibility: Format clarification data for verification
public struct VerificationContextFormatter {
    public init() {}

    /// Build enriched context including clarifications for PRD verification
    public func buildEnrichedVerificationContext(
        originalRequest: String,
        clarifications: [UUID: String],
        questions: [ClarificationQuestion<String, Int, String>]
    ) -> String {
        var context = "ORIGINAL REQUEST:\n\(originalRequest)\n\n"

        if !clarifications.isEmpty {
            context += "USER CLARIFICATIONS:\n"
            for question in questions {
                if let answer = clarifications[question.id] {
                    context += "Q: \(question.question)\nA: \(answer)\n\n"
                }
            }

            context += """
            VERIFICATION REQUIREMENTS:
            1. PRD must address all points in original request
            2. PRD must incorporate ALL user clarifications listed above
            3. PRD must be consistent with all clarification answers
            4. PRD must not contradict any clarifications
            5. PRD must not ignore or misinterpret any clarifications
            """
        }

        return context
    }

    /// Format clarification questions for verification
    public func formatQuestionsForVerification(
        _ questions: [ClarificationQuestion<String, Int, String>]
    ) -> String {
        questions
            .sorted { $0.priority > $1.priority }
            .map { "- [\($0.category.value)] \($0.question)" }
            .joined(separator: "\n")
    }

    /// Format PRD document for verification
    public func formatPRDForVerification(_ document: PRDDocument) -> String {
        var text = "Title: \(document.title)\n\n"

        for section in document.sections {
            text += "## \(section.title)\n"
            text += "\(section.content)\n\n"
        }

        return text
    }
}
