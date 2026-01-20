import Foundation

/// Captures visual analysis of mockups and their influence
/// Enables learning from mockup interpretation
public struct MockupAnalysisTrace: Identifiable, Sendable, Codable {
    public let id: UUID
    public let mockupId: UUID
    public let prdId: UUID?  // Nullable: set later when mockup is associated with PRD
    public let llmInteractionId: UUID?
    public let analysisPrompt: String
    public let llmResponse: String
    public let detectedPatterns: [DetectedUIPattern]
    public let uiComponents: [String]
    public let colorScheme: ColorSchemeInfo?
    public let layoutType: String?
    public let uncertainties: [String]
    public let clarificationQuestions: [String]
    public let influencedSections: [UUID]
    public let confidenceScore: Double?
    public let visionModel: String
    public let visionProvider: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        mockupId: UUID,
        prdId: UUID? = nil,
        llmInteractionId: UUID? = nil,
        analysisPrompt: String,
        llmResponse: String,
        detectedPatterns: [DetectedUIPattern] = [],
        uiComponents: [String] = [],
        colorScheme: ColorSchemeInfo? = nil,
        layoutType: String? = nil,
        uncertainties: [String] = [],
        clarificationQuestions: [String] = [],
        influencedSections: [UUID] = [],
        confidenceScore: Double? = nil,
        visionModel: String,
        visionProvider: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.mockupId = mockupId
        self.prdId = prdId
        self.llmInteractionId = llmInteractionId
        self.analysisPrompt = analysisPrompt
        self.llmResponse = llmResponse
        self.detectedPatterns = detectedPatterns
        self.uiComponents = uiComponents
        self.colorScheme = colorScheme
        self.layoutType = layoutType
        self.uncertainties = uncertainties
        self.clarificationQuestions = clarificationQuestions
        self.influencedSections = influencedSections
        self.confidenceScore = confidenceScore
        self.visionModel = visionModel
        self.visionProvider = visionProvider
        self.createdAt = createdAt
    }
}
