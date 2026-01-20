import Foundation

/// Configuration for PRD generation
/// Following Single Responsibility Principle - represents generation config
public struct Configuration: Sendable {
    public let thinkingMode: ThinkingMode
    public let enableProfessionalAnalysis: Bool
    public let enableCodebaseContext: Bool
    public let maxTokens: Int
    public let temperature: Double
    public let privacyLevel: PrivacyLevel

    public init(
        thinkingMode: ThinkingMode = .standard,
        enableProfessionalAnalysis: Bool = true,
        enableCodebaseContext: Bool = true,
        maxTokens: Int = 4000,
        temperature: Double = 0.7,
        privacyLevel: PrivacyLevel = .standard
    ) {
        self.thinkingMode = thinkingMode
        self.enableProfessionalAnalysis = enableProfessionalAnalysis
        self.enableCodebaseContext = enableCodebaseContext
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.privacyLevel = privacyLevel
    }
}
