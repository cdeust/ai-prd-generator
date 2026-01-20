import Foundation

/// PRD Section entity
/// Following Single Responsibility Principle - represents PRD section
public struct PRDSection: Identifiable, Sendable, Codable {
    public let id: UUID
    public let type: SectionType
    public let title: String
    public let content: String
    public let order: Int
    public let confidence: Double?
    public let assumptions: [Assumption]
    public let thinkingStrategy: String?
    public let openAPISpec: OpenAPISpecification?
    public let testSuite: TestSuite?

    public init(
        id: UUID = UUID(),
        type: SectionType,
        title: String,
        content: String,
        order: Int,
        confidence: Double? = nil,
        assumptions: [Assumption] = [],
        thinkingStrategy: String? = nil,
        openAPISpec: OpenAPISpecification? = nil,
        testSuite: TestSuite? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.order = order
        self.confidence = confidence
        self.assumptions = assumptions
        self.thinkingStrategy = thinkingStrategy
        self.openAPISpec = openAPISpec
        self.testSuite = testSuite
    }

    public func toMarkdown() -> String {
        """
        ## \(title)

        \(content)
        """
    }

    /// Validate PRD section
    /// - Throws: ValidationError if section data is invalid
    public func validate() throws {
        try validateTitle()
        try validateContent()
        try validateOrder()
        try validateConfidence()
    }

    private func validateTitle() throws {
        guard !title.isEmpty else {
            throw ValidationError.missingRequired(field: "title")
        }
    }

    private func validateContent() throws {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.missingRequired(field: "content")
        }
    }

    private func validateOrder() throws {
        guard order >= 0 else {
            throw ValidationError.outOfRange(
                field: "order",
                min: "0",
                max: nil
            )
        }
    }

    private func validateConfidence() throws {
        guard let confidence = confidence else { return }

        guard (0.0...1.0).contains(confidence) else {
            throw ValidationError.outOfRange(
                field: "confidence",
                min: "0.0",
                max: "1.0"
            )
        }
    }
}
