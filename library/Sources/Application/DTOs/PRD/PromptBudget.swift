import Foundation

/// Prompt budget allocation for PRD generation
/// Represents how tokens are divided between prompt and output
public struct PromptBudget: Sendable {
    public let contextWindowSize: Int
    public let safetyBuffer: Int
    public let promptBudget: Int
    public let outputBudget: Int
    public let providerName: String

    public init(
        contextWindowSize: Int,
        safetyBuffer: Int,
        promptBudget: Int,
        outputBudget: Int,
        providerName: String
    ) {
        self.contextWindowSize = contextWindowSize
        self.safetyBuffer = safetyBuffer
        self.promptBudget = promptBudget
        self.outputBudget = outputBudget
        self.providerName = providerName
    }

    public var totalAvailable: Int {
        contextWindowSize - safetyBuffer
    }

    public var compressionNeeded: Bool {
        // Compression needed for small context windows
        contextWindowSize < 16_000
    }
}
