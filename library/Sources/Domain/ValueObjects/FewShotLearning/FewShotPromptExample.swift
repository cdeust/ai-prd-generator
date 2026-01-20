import Foundation

/// Few-shot prompt example for in-context learning
public struct FewShotPromptExample: Sendable, Codable {
    /// Unique identifier
    public let id: UUID

    /// Example input/prompt
    public let input: String

    /// Expected output
    public let output: String

    /// Category (section type, task type, etc.)
    public let category: String

    /// Quality score (0.0-1.0)
    public let quality: Double

    /// Optional metadata
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        input: String,
        output: String,
        category: String,
        quality: Double,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.input = input
        self.output = output
        self.category = category
        self.quality = quality
        self.metadata = metadata
    }
}
