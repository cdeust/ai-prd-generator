import Foundation

/// Context information about where a gap was detected
public struct GapContext: Codable, Sendable, Equatable {
    /// PRD section where the gap was found
    public let section: String?

    /// Relevant text snippet highlighting the gap
    public let snippet: String?

    /// Related entities (mockups, code files, etc.)
    public let relatedEntities: [String]

    public init(
        section: String? = nil,
        snippet: String? = nil,
        relatedEntities: [String] = []
    ) {
        self.section = section
        self.snippet = snippet
        self.relatedEntities = relatedEntities
    }
}
