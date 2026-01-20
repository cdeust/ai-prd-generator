import Foundation

/// Evidence source supporting a resolution
public struct EvidenceSource: Codable, Sendable, Equatable {
    /// Type of evidence source
    public let type: EvidenceType

    /// Reference to the source (file path, URL, reasoning chain, etc.)
    public let reference: String

    /// Relevance score (0.0 - 1.0)
    public let relevance: Double

    /// Snippet or excerpt from the source
    public let excerpt: String?

    public init(
        type: EvidenceType,
        reference: String,
        relevance: Double,
        excerpt: String? = nil
    ) {
        self.type = type
        self.reference = reference
        self.relevance = min(max(relevance, 0.0), 1.0)
        self.excerpt = excerpt
    }
}
