import Foundation
import Domain

/// Cost estimate for PRD generation
public struct CostEstimate: Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let inputCost: Double
    public let outputCost: Double
    public let totalCost: Double
    public let model: ModelType

    public init(
        inputTokens: Int,
        outputTokens: Int,
        inputCost: Double,
        outputCost: Double,
        totalCost: Double,
        model: ModelType
    ) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.inputCost = inputCost
        self.outputCost = outputCost
        self.totalCost = totalCost
        self.model = model
    }

    /// Format cost as USD string
    public var formattedCost: String {
        if totalCost == 0.0 {
            return "$0.00 (on-device)"
        }
        return String(format: "$%.2f", totalCost)
    }
}
