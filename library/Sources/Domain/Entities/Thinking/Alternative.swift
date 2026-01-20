import Foundation

/// Alternative solution or approach
/// Following Single Responsibility: Represents alternative option only
public struct Alternative: Identifiable, Sendable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let pros: [String]
    public let cons: [String]
    public let score: Double

    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        pros: [String],
        cons: [String],
        score: Double
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.pros = pros
        self.cons = cons
        self.score = score
    }
}
