import Foundation

/// Core domain entity representing a Product Requirements Document
/// Following Single Responsibility Principle - manages PRD data
public struct PRDDocument: Identifiable, Sendable, Codable {
    public let id: UUID
    public let userId: UUID
    public let title: String
    public let description: String?
    public let version: String
    public let status: PRDStatus
    public let privacyLevel: PRDPrivacyLevel
    public let sections: [PRDSection]
    public let metadata: DocumentMetadata
    public let professionalAnalysis: ProfessionalAnalysis?
    public let thoughtChain: ThoughtChain?
    public let mockups: [Mockup]
    public let stackContext: StackContext?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        description: String? = nil,
        version: String = "1.0",
        status: PRDStatus = .draft,
        privacyLevel: PRDPrivacyLevel = .private,
        sections: [PRDSection] = [],
        metadata: DocumentMetadata,
        professionalAnalysis: ProfessionalAnalysis? = nil,
        thoughtChain: ThoughtChain? = nil,
        mockups: [Mockup] = [],
        stackContext: StackContext? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.version = version
        self.status = status
        self.privacyLevel = privacyLevel
        self.sections = sections
        self.metadata = metadata
        self.professionalAnalysis = professionalAnalysis
        self.thoughtChain = thoughtChain
        self.mockups = mockups
        self.stackContext = stackContext
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public func isComplete() -> Bool {
        checkCompleteness()
    }

    public var completionPercentage: Double {
        calculateCompletion()
    }

    public func toMarkdown() -> String {
        buildMarkdown()
    }

    private func checkCompleteness() -> Bool {
        let required: Set<SectionType> = [
            .overview, .requirements, .technicalSpecification
        ]
        let existing = Set(sections.map { $0.type })
        return required.isSubset(of: existing)
    }

    private func calculateCompletion() -> Double {
        guard !sections.isEmpty else { return 0.0 }
        let completed = sections.filter { $0.content.count > 100 }
        return Double(completed.count) / Double(sections.count)
    }

    private func buildMarkdown() -> String {
        var md = "# \(title)\n\n"
        md += "**Version:** \(version)\n\n"

        // Linux-compatible date formatting
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        md += "**Created:** \(formatter.string(from: createdAt))\n\n"

        md += "---\n\n"

        for section in sections {
            md += section.toMarkdown()
            md += "\n\n"
        }

        return md
    }

    /// Validate PRD document
    /// - Throws: ValidationError if document structure is invalid
    public func validate() throws {
        try validateTitle()
        try validateVersion()
        try validateDates()
        try validateSections()
        try validateStackContext()
    }

    private func validateTitle() throws {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.missingRequired(field: "title")
        }
    }

    private func validateVersion() throws {
        let pattern = "^\\d+\\.\\d+(\\.\\d+)?$"

        // Linux-compatible regex matching using NSRegularExpression
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            throw ValidationError.invalidFormat(
                field: "version",
                expected: "valid regex pattern"
            )
        }

        let range = NSRange(version.startIndex..., in: version)
        guard regex.firstMatch(in: version, range: range) != nil else {
            throw ValidationError.invalidFormat(
                field: "version",
                expected: "semantic version (x.y or x.y.z)"
            )
        }
    }

    private func validateDates() throws {
        guard updatedAt >= createdAt else {
            throw ValidationError.custom(
                "updatedAt cannot be before createdAt"
            )
        }
    }

    private func validateSections() throws {
        for section in sections {
            try section.validate()
        }
    }

    private func validateStackContext() throws {
        try stackContext?.validate()
    }
}
