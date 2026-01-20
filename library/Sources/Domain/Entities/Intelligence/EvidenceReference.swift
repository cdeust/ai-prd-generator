import Foundation

/// Reference to evidence used in reasoning
public struct EvidenceReference: Sendable, Codable {
    public let type: ThinkingEvidenceType
    public let id: UUID
    public let relevance: Double?
    public let description: String?

    public init(
        type: ThinkingEvidenceType,
        id: UUID,
        relevance: Double? = nil,
        description: String? = nil
    ) {
        self.type = type
        self.id = id
        self.relevance = relevance
        self.description = description
    }
}
