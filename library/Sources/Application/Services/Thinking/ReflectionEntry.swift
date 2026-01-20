import Foundation
import Domain

/// Single reflection entry in memory
public struct ReflectionEntry: Identifiable, Sendable {
    public let id: UUID
    public let iteration: Int
    public let attempt: ThoughtChain
    public let qualityScore: Double
    public let strengths: [String]
    public let weaknesses: [String]
    public let suggestedImprovements: [String]
    public let timestamp: Date

    public init(
        id: UUID,
        iteration: Int,
        attempt: ThoughtChain,
        qualityScore: Double,
        strengths: [String],
        weaknesses: [String],
        suggestedImprovements: [String],
        timestamp: Date
    ) {
        self.id = id
        self.iteration = iteration
        self.attempt = attempt
        self.qualityScore = qualityScore
        self.strengths = strengths
        self.weaknesses = weaknesses
        self.suggestedImprovements = suggestedImprovements
        self.timestamp = timestamp
    }
}
