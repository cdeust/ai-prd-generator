import Foundation

/// Document metadata
/// Following Single Responsibility Principle - represents document metadata
public struct DocumentMetadata: Sendable, Codable {
    public let author: String
    public let projectName: String
    public let aiProvider: String
    public let generationDuration: TimeInterval?
    public let generationApproach: String?
    public let codebaseId: UUID?
    public let thinkingStrategy: String?

    public init(
        author: String,
        projectName: String,
        aiProvider: String,
        generationDuration: TimeInterval? = nil,
        generationApproach: String? = nil,
        codebaseId: UUID? = nil,
        thinkingStrategy: String? = nil
    ) {
        self.author = author
        self.projectName = projectName
        self.aiProvider = aiProvider
        self.generationDuration = generationDuration
        self.generationApproach = generationApproach
        self.codebaseId = codebaseId
        self.thinkingStrategy = thinkingStrategy
    }
}
