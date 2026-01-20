import Foundation

/// Generic clarification question with type parameters
///
/// Professional generic design - category, priority, and gap types are parameterized.
/// Fully extensible without code changes.
public struct ClarificationQuestion<CT, PT, GT>: Sendable, Codable, Identifiable
    where CT: Hashable & Codable & Sendable,
          PT: Comparable & Codable & Sendable & Hashable,
          GT: Hashable & Codable & Sendable
{
    public let id: UUID
    public let category: QuestionCategory<CT>
    public let question: String
    public let rationale: String
    public let examples: [String]
    public let priority: QuestionPriority<PT>
    public let detectedGap: GapType<GT>

    public init(
        id: UUID = UUID(),
        category: QuestionCategory<CT>,
        question: String,
        rationale: String,
        examples: [String],
        priority: QuestionPriority<PT>,
        detectedGap: GapType<GT>
    ) {
        self.id = id
        self.category = category
        self.question = question
        self.rationale = rationale
        self.examples = examples
        self.priority = priority
        self.detectedGap = detectedGap
    }

    /// Validate question completeness
    public func validate() throws {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyQuestion
        }
        guard !rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyRationale
        }
    }

    public enum ValidationError: Error {
        case emptyQuestion
        case emptyRationale
    }
}
