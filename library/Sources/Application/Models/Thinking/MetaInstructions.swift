import Foundation

/// Meta-instructions for guiding the prompting strategy
public struct MetaInstructions: Sendable {
    public let role: Role?
    public let reasoningStrategy: String?
    public let perspectives: [String]
    public let qualityCriteria: [String]

    public init(
        role: Role? = nil,
        reasoningStrategy: String? = nil,
        perspectives: [String] = [],
        qualityCriteria: [String] = []
    ) {
        self.role = role
        self.reasoningStrategy = reasoningStrategy
        self.perspectives = perspectives
        self.qualityCriteria = qualityCriteria
    }
}
