import Foundation
import Domain

/// Combined result of multi-modal input analysis
public struct MultiModalAnalysisResult: Sendable {
    /// User's original text description
    public let textDescription: String

    /// Mockup analysis results (empty if no mockups provided)
    public let mockupAnalysis: [MockupAnalysisResult]

    /// Codebase context (nil if no codebase provided)
    public let codebaseContext: CodebaseContext?

    /// Analysis timestamp
    public let analyzedAt: Date

    public init(
        textDescription: String,
        mockupAnalysis: [MockupAnalysisResult],
        codebaseContext: CodebaseContext?,
        analyzedAt: Date
    ) {
        self.textDescription = textDescription
        self.mockupAnalysis = mockupAnalysis
        self.codebaseContext = codebaseContext
        self.analyzedAt = analyzedAt
    }

    /// Total UI components across all mockups
    public var totalComponents: Int {
        mockupAnalysis.reduce(0) { $0 + $1.components.count }
    }

    /// All identified user flows
    public var allUserFlows: [UserFlow] {
        mockupAnalysis.flatMap { $0.flows }
    }

    /// All data requirements
    public var allDataRequirements: [InferredDataRequirement] {
        mockupAnalysis.flatMap { $0.dataRequirements }
    }

    /// Check if mockups were provided
    public var hasMockups: Bool {
        !mockupAnalysis.isEmpty
    }

    /// Check if codebase context was provided
    public var hasCodebase: Bool {
        codebaseContext != nil
    }

    /// Check if analysis is complete
    public var isComplete: Bool {
        !textDescription.isEmpty
    }
}
