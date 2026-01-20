import Foundation
import Domain

/// Unified context aggregated from multi-modal analysis
public struct AggregatedContext: Sendable {
    /// Original text description
    public let textDescription: String

    /// UI insights from mockup analysis
    public let uiInsights: UIInsights

    /// Data insights from mockup analysis
    public let dataInsights: DataInsights

    /// Code insights from codebase analysis (optional)
    public let codeInsights: CodeInsights?

    /// Cross-cutting concerns identified
    public let crossCuttingConcerns: [String]

    /// Aggregation timestamp
    public let aggregatedAt: Date

    public init(
        textDescription: String,
        uiInsights: UIInsights,
        dataInsights: DataInsights,
        codeInsights: CodeInsights?,
        crossCuttingConcerns: [String],
        aggregatedAt: Date
    ) {
        self.textDescription = textDescription
        self.uiInsights = uiInsights
        self.dataInsights = dataInsights
        self.codeInsights = codeInsights
        self.crossCuttingConcerns = crossCuttingConcerns
        self.aggregatedAt = aggregatedAt
    }

    /// Check if context includes UI insights
    public var hasUIInsights: Bool {
        uiInsights.totalScreens > 0
    }

    /// Check if context includes code insights
    public var hasCodeInsights: Bool {
        codeInsights != nil
    }

    /// Context richness score (0.0 - 1.0)
    public var richnessScore: Double {
        var score = 0.0

        // Text (baseline)
        score += 0.2

        // UI insights
        if hasUIInsights {
            score += 0.3
        }

        // Data insights
        if dataInsights.totalFields > 0 {
            score += 0.2
        }

        // Code insights
        if hasCodeInsights {
            score += 0.3
        }

        return min(score, 1.0)
    }
}
