import Foundation

/// An identified information gap in PRD generation.
///
/// Represents missing information that needs to be resolved to produce a complete,
/// high-quality PRD. Each gap has a category, priority, and question that needs answering.
/// The system attempts to auto-resolve gaps using various strategies before escalating to the user.
public struct InformationGap: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for this gap
    public let id: UUID

    /// Category of the missing information
    public let category: GapCategory

    /// Priority level determining resolution urgency
    public let priority: GapPriority

    /// The question that needs to be answered
    public let question: String

    /// Context about where the gap was identified
    public let context: GapContext

    /// Resolution attempts made for this gap
    public let resolutionAttempts: [ResolutionAttempt]

    /// Current resolution status
    public let status: GapStatus

    /// When the gap was first detected
    public let detectedAt: Date

    /// When the gap was resolved (if applicable)
    public let resolvedAt: Date?

    public init(
        id: UUID = UUID(),
        category: GapCategory,
        priority: GapPriority,
        question: String,
        context: GapContext,
        resolutionAttempts: [ResolutionAttempt] = [],
        status: GapStatus = .detected,
        detectedAt: Date = Date(),
        resolvedAt: Date? = nil
    ) {
        self.id = id
        self.category = category
        self.priority = priority
        self.question = question
        self.context = context
        self.resolutionAttempts = resolutionAttempts
        self.status = status
        self.detectedAt = detectedAt
        self.resolvedAt = resolvedAt
    }

    /// Add a new resolution attempt
    public func addingResolutionAttempt(_ attempt: ResolutionAttempt) -> InformationGap {
        InformationGap(
            id: id,
            category: category,
            priority: priority,
            question: question,
            context: context,
            resolutionAttempts: resolutionAttempts + [attempt],
            status: status,
            detectedAt: detectedAt,
            resolvedAt: resolvedAt
        )
    }

    /// Mark gap as resolved
    public func markingAsResolved(at date: Date = Date()) -> InformationGap {
        InformationGap(
            id: id,
            category: category,
            priority: priority,
            question: question,
            context: context,
            resolutionAttempts: resolutionAttempts,
            status: .resolved,
            detectedAt: detectedAt,
            resolvedAt: date
        )
    }

    /// Mark gap as requiring user input
    public func markingAsRequiresUser() -> InformationGap {
        InformationGap(
            id: id,
            category: category,
            priority: priority,
            question: question,
            context: context,
            resolutionAttempts: resolutionAttempts,
            status: .requiresUser,
            detectedAt: detectedAt,
            resolvedAt: resolvedAt
        )
    }

    /// Best resolution attempt (highest confidence)
    public var bestResolution: ResolutionAttempt? {
        resolutionAttempts.max(by: { $0.confidence.score < $1.confidence.score })
    }

    /// Whether this gap has been successfully resolved
    public var isResolved: Bool {
        status == .resolved && resolvedAt != nil
    }
}
