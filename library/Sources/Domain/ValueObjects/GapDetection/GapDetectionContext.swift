import Foundation

/// Context for gap detection
public struct GapDetectionContext: Codable, Sendable {
    /// User-provided requirements or description
    public let userRequirements: String?

    /// Available mockups for analysis
    public let mockupPaths: [String]

    /// Codebase context (indexed files, symbols, etc.)
    public let codebaseContext: CodebaseGapContext?

    /// Previous PRD sections already generated
    public let existingSections: [String: String]

    /// Template being used (if any)
    public let templateSections: [String]?

    public init(
        userRequirements: String? = nil,
        mockupPaths: [String] = [],
        codebaseContext: CodebaseGapContext? = nil,
        existingSections: [String: String] = [:],
        templateSections: [String]? = nil
    ) {
        self.userRequirements = userRequirements
        self.mockupPaths = mockupPaths
        self.codebaseContext = codebaseContext
        self.existingSections = existingSections
        self.templateSections = templateSections
    }
}
