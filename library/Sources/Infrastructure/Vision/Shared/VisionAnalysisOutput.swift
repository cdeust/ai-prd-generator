import Foundation

/// Generic intermediate DTO for vision analysis output
/// Used by all vision providers (Anthropic, OpenAI, Gemini)
public struct VisionAnalysisOutput: Codable, Sendable {
    public let screenName: String?
    public let screenDescription: String?
    public let components: [ComponentDTO]
    public let interactions: [InteractionDTO]
    public let dataRequirements: [DataRequirementDTO]
    public let userFlows: [UserFlowDTO]

    /// Layout type detected (e.g., "list", "grid", "form", "dashboard", "detail")
    public let layoutType: String?

    /// Areas where the LLM is uncertain about the analysis
    public let uncertainties: [String]?

    /// Questions the LLM suggests asking to clarify the mockup
    public let suggestedClarifications: [String]?

    public struct ComponentDTO: Codable, Sendable {
        public let type: String
        public let label: String?
        public let placeholder: String?
        public let position: PositionDTO
        public let state: String?
        public let isInteractive: Bool
        public let accessibilityLabel: String?
    }

    public struct PositionDTO: Codable, Sendable {
        public let x: Double
        public let y: Double
        public let width: Double
        public let height: Double
    }

    public struct InteractionDTO: Codable, Sendable {
        public let componentId: String
        public let trigger: String
        public let action: String
        public let targetScreen: String?
        public let feedback: FeedbackDTO?
    }

    public struct FeedbackDTO: Codable, Sendable {
        public let visual: String?
        public let haptic: String?
        public let audio: String?
    }

    public struct DataRequirementDTO: Codable, Sendable {
        public let fieldName: String
        public let dataType: String
        public let isRequired: Bool
        public let validation: [String]
        public let placeholder: String?
        public let helpText: String?
    }

    public struct UserFlowDTO: Codable, Sendable {
        public let name: String
        public let startScreen: String
        public let endScreen: String
        public let steps: [String]
    }
}

