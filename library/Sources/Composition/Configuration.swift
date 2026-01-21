import Foundation
import InfrastructureCore

/// Configuration for application factory
/// Used by all presentation channels (CLI, REST, WebSocket)
public struct Configuration: Sendable {
    public let aiProvider: AIProviderType
    public let aiAPIKey: String?
    public let aiModel: String?
    public let storageType: StorageType
    public let storagePath: URL
    public let databaseURL: String?

    public let openAIKey: String?
    public let anthropicKey: String?
    public let geminiKey: String?
    public let openRouterKey: String?
    public let bedrockAccessKeyId: String?
    public let bedrockSecretAccessKey: String?
    public let bedrockRegion: String?

    public init(
        aiProvider: AIProviderType,
        aiAPIKey: String?,
        aiModel: String?,
        storageType: StorageType,
        storagePath: URL,
        databaseURL: String? = nil,
        openAIKey: String? = nil,
        anthropicKey: String? = nil,
        geminiKey: String? = nil,
        openRouterKey: String? = nil,
        bedrockAccessKeyId: String? = nil,
        bedrockSecretAccessKey: String? = nil,
        bedrockRegion: String? = nil
    ) {
        self.aiProvider = aiProvider
        self.aiAPIKey = aiAPIKey
        self.aiModel = aiModel
        self.storageType = storageType
        self.storagePath = storagePath
        self.databaseURL = databaseURL
        self.openAIKey = openAIKey
        self.anthropicKey = anthropicKey
        self.geminiKey = geminiKey
        self.openRouterKey = openRouterKey
        self.bedrockAccessKeyId = bedrockAccessKeyId
        self.bedrockSecretAccessKey = bedrockSecretAccessKey
        self.bedrockRegion = bedrockRegion
    }

    /// Default configuration (Apple Intelligence, in-memory storage)
    public static let `default` = Configuration(
        aiProvider: .appleFoundationModels,
        aiAPIKey: nil,
        aiModel: nil,
        storageType: .memory,
        storagePath: URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".ai-prd")
    )

    /// Load configuration from environment variables
    public static func fromEnvironment() -> Configuration {
        let providerString = ProcessInfo.processInfo.environment["AI_PROVIDER"] ?? "apple"
        let aiProvider = parseAIProvider(providerString)
        let storage = parseStorageConfiguration()
        let keys = parseAIProviderKeys()

        return Configuration(
            aiProvider: aiProvider,
            aiAPIKey: keys.primary,
            aiModel: ProcessInfo.processInfo.environment["AI_MODEL"],
            storageType: storage.type,
            storagePath: storage.path,
            databaseURL: storage.databaseURL,
            openAIKey: keys.openAI,
            anthropicKey: keys.anthropic,
            geminiKey: keys.gemini,
            openRouterKey: keys.openRouter,
            bedrockAccessKeyId: keys.bedrockAccessKeyId,
            bedrockSecretAccessKey: keys.bedrockSecretAccessKey,
            bedrockRegion: keys.bedrockRegion
        )
    }

    private struct StorageConfiguration {
        let type: StorageType
        let path: URL
        let databaseURL: String?
    }

    private struct AIProviderKeys {
        let openAI: String?
        let anthropic: String?
        let gemini: String?
        let openRouter: String?
        let bedrockAccessKeyId: String?
        let bedrockSecretAccessKey: String?
        let bedrockRegion: String?
        let primary: String?
    }

    private static func parseStorageConfiguration() -> StorageConfiguration {
        let databaseURL = ProcessInfo.processInfo.environment["DATABASE_URL"]

        let storageType: StorageType
        if let explicitType = ProcessInfo.processInfo.environment["STORAGE_TYPE"] {
            storageType = StorageType(rawValue: explicitType) ?? .memory
        } else if databaseURL != nil {
            // Auto-detect PostgreSQL (local Docker or native PostgreSQL)
            storageType = .postgres
        } else {
            // Default to in-memory for standalone skill
            storageType = .memory
        }

        let storagePath = ProcessInfo.processInfo.environment["STORAGE_PATH"]
            .map { URL(fileURLWithPath: $0) }
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".ai-prd")

        return StorageConfiguration(
            type: storageType,
            path: storagePath,
            databaseURL: databaseURL
        )
    }

    private static func parseAIProviderKeys() -> AIProviderKeys {
        let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        let anthropicKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        let geminiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
        let openRouterKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
        let bedrockAccessKeyId = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"]
        let bedrockSecretAccessKey = ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"]
        let bedrockRegion = ProcessInfo.processInfo.environment["AWS_REGION"]
        let primaryKey = openAIKey ?? anthropicKey ?? geminiKey
        return AIProviderKeys(
            openAI: openAIKey,
            anthropic: anthropicKey,
            gemini: geminiKey,
            openRouter: openRouterKey,
            bedrockAccessKeyId: bedrockAccessKeyId,
            bedrockSecretAccessKey: bedrockSecretAccessKey,
            bedrockRegion: bedrockRegion,
            primary: primaryKey
        )
    }

    private static func parseAIProvider(_ value: String) -> AIProviderType {
        switch value.lowercased() {
        case "apple", "appleintelligence", "foundation":
            return .appleFoundationModels
        case "openai", "gpt":
            return .openAI
        case "anthropic", "claude":
            return .anthropic
        case "gemini", "google":
            return .gemini
        case "mock", "test", "demo":
            return .mock
        default:
            return .appleFoundationModels
        }
    }
}
