import Foundation
import Domain

/// DTO representing a request to generate a PRD
/// Following Single Responsibility Principle - encapsulates PRD generation request data
public struct PRDRequest: Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let title: String
    public let description: String
    public let requirements: [Requirement]
    public let constraints: [String]
    public let platform: Platform?
    public let metadata: [String: String]
    public let codebaseId: UUID?
    public let templateId: UUID?
    public let mockupFileIds: [String]?
    public let priority: Priority
    public let targetAudience: String?
    public let privacyLevel: PRDPrivacyLevel
    public let createdAt: Date
    /// Question IDs from Phase 1 analysis - used to link traces between phases
    public let phase1QuestionIds: [UUID]?

    public init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        description: String,
        requirements: [Requirement] = [],
        constraints: [String] = [],
        platform: Platform? = nil,
        metadata: [String: String] = [:],
        codebaseId: UUID? = nil,
        templateId: UUID? = nil,
        mockupFileIds: [String]? = nil,
        priority: Priority = .medium,
        targetAudience: String? = nil,
        privacyLevel: PRDPrivacyLevel = .private,
        createdAt: Date = Date(),
        phase1QuestionIds: [UUID]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.requirements = requirements
        self.constraints = constraints
        self.platform = platform
        self.metadata = metadata
        self.codebaseId = codebaseId
        self.templateId = templateId
        self.mockupFileIds = mockupFileIds
        self.priority = priority
        self.targetAudience = targetAudience
        self.privacyLevel = privacyLevel
        self.createdAt = createdAt
        self.phase1QuestionIds = phase1QuestionIds
    }

    /// Validate request data
    public func validate() throws {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PRDRequestError.emptyTitle
        }

        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PRDRequestError.emptyDescription
        }

        // Codebase and mockups are optional - PRD can be generated from description alone
    }

    /// Check if linked to codebase
    public var hasCodebaseContext: Bool {
        codebaseId != nil
    }

    /// Check if using custom template
    public var hasCustomTemplate: Bool {
        templateId != nil
    }

    /// Check if mockups provided
    public var hasMockups: Bool {
        mockupFileIds != nil && !(mockupFileIds?.isEmpty ?? true)
    }
}
