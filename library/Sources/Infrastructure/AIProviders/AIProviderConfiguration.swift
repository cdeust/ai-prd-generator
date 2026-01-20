import Foundation

/// AI Provider Configuration
/// Encapsulates provider-specific settings
/// Following value type for immutability
public struct AIProviderConfiguration: Sendable {
    public let type: AIProviderType
    public let apiKey: String?
    public let model: String?

    // AWS Bedrock-specific fields
    public let region: String?
    public let accessKeyId: String?
    public let secretAccessKey: String?

    public init(
        type: AIProviderType,
        apiKey: String? = nil,
        model: String? = nil,
        region: String? = nil,
        accessKeyId: String? = nil,
        secretAccessKey: String? = nil
    ) {
        self.type = type
        self.apiKey = apiKey
        self.model = model
        self.region = region
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
    }
}
