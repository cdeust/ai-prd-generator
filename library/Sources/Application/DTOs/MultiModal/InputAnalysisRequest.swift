import Foundation
import Domain

/// Request for multi-modal input analysis
public struct InputAnalysisRequest: Sendable {
    /// User's text description of requirements
    public let textDescription: String

    /// Optional UI mockup images
    public let mockupImages: [MockupImage]?

    /// Optional codebase identifier
    public let codebaseId: UUID?

    /// Optional analysis guidance
    public let analysisGuidance: String?

    public init(
        textDescription: String,
        mockupImages: [MockupImage]? = nil,
        codebaseId: UUID? = nil,
        analysisGuidance: String? = nil
    ) {
        self.textDescription = textDescription
        self.mockupImages = mockupImages
        self.codebaseId = codebaseId
        self.analysisGuidance = analysisGuidance
    }

    /// Check if request includes mockups
    public var hasMockups: Bool {
        mockupImages?.isEmpty == false
    }

    /// Check if request includes codebase
    public var hasCodebase: Bool {
        codebaseId != nil
    }

    /// Input complexity level
    public var complexity: InputComplexity {
        switch (hasMockups, hasCodebase) {
        case (true, true): return .high
        case (true, false), (false, true): return .medium
        case (false, false): return .low
        }
    }
}
