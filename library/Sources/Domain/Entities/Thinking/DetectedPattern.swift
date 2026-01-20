import Foundation

/// Pattern detected in thinking or code
/// Following Single Responsibility: Represents detected pattern only
public struct DetectedPattern: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let description: String
    public let isAntiPattern: Bool
    public let occurrences: Int
    public let recommendation: String
    public let examples: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        isAntiPattern: Bool,
        occurrences: Int,
        recommendation: String,
        examples: [String]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isAntiPattern = isAntiPattern
        self.occurrences = occurrences
        self.recommendation = recommendation
        self.examples = examples
    }
}
