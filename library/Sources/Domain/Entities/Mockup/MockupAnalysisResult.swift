import Foundation

/// Result of analyzing a UI mockup image
public struct MockupAnalysisResult: Sendable, Codable, Equatable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Mockup image identifier
    public let mockupId: UUID

    /// Analysis timestamp
    public let analyzedAt: Date

    /// Extracted UI components
    public let components: [UIComponent]

    /// Identified user flows
    public let flows: [UserFlow]

    /// Detected interactions
    public let interactions: [Interaction]

    /// Inferred data requirements
    public let dataRequirements: [InferredDataRequirement]

    /// Analysis metadata
    public let metadata: AnalysisMetadata

    /// Screen name or title
    public let screenName: String?

    /// Screen description
    public let screenDescription: String?

    /// Layout type (e.g., "list", "grid", "form", "dashboard", "detail")
    public let layoutType: String?

    /// Areas where the LLM is uncertain about the analysis
    public let uncertainties: [String]

    /// Questions the LLM suggests asking to clarify the mockup
    public let suggestedClarifications: [String]

    public init(
        id: UUID = UUID(),
        mockupId: UUID,
        analyzedAt: Date = Date(),
        components: [UIComponent],
        flows: [UserFlow] = [],
        interactions: [Interaction] = [],
        dataRequirements: [InferredDataRequirement] = [],
        metadata: AnalysisMetadata,
        screenName: String? = nil,
        screenDescription: String? = nil,
        layoutType: String? = nil,
        uncertainties: [String] = [],
        suggestedClarifications: [String] = []
    ) {
        self.id = id
        self.mockupId = mockupId
        self.analyzedAt = analyzedAt
        self.components = components
        self.flows = flows
        self.interactions = interactions
        self.dataRequirements = dataRequirements
        self.metadata = metadata
        self.screenName = screenName
        self.screenDescription = screenDescription
        self.layoutType = layoutType
        self.uncertainties = uncertainties
        self.suggestedClarifications = suggestedClarifications
    }

    /// Total count of all extracted elements
    public var totalElementCount: Int {
        components.count + flows.count + interactions.count + dataRequirements.count
    }

    /// Get interactive components
    public var interactiveComponents: [UIComponent] {
        components.filter { $0.isInteractive }
    }

    /// Get input fields
    public var inputFields: [UIComponent] {
        components.filter { $0.isInputField }
    }

    /// Get required data fields
    public var requiredDataFields: [InferredDataRequirement] {
        dataRequirements.filter { $0.isRequired }
    }

    /// Check if analysis is complete
    public var isComplete: Bool {
        !components.isEmpty
    }

    /// Validation
    public func validate() throws {
        guard !components.isEmpty else {
            throw MockupAnalysisError.noComponentsFound
        }

        guard metadata.confidence > 0.0 && metadata.confidence <= 1.0 else {
            throw MockupAnalysisError.invalidConfidence(metadata.confidence)
        }
    }
}
