import Foundation

/// Parameters used for an LLM call
/// Captures configuration for reproducibility
public struct LLMParameters: Sendable, Codable {
    public let temperature: Double?
    public let maxTokens: Int?
    public let topP: Double?
    public let topK: Int?
    public let stopSequences: [String]?

    public init(
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        topK: Int? = nil,
        stopSequences: [String]? = nil
    ) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.topK = topK
        self.stopSequences = stopSequences
    }
}
