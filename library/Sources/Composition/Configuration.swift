import AIPRDEncryptionEngine
import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Application
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

    /// License tier determines feature access
    /// - Free: Basic strategies, basic RAG, basic verification
    /// - Trial: Full access during 14-day evaluation
    /// - Licensed: Full access to all advanced features
    public let licenseTier: LicenseTier

    /// Full license resolution with crypto verification details
    public let licenseResolution: LicenseResolution

    public let openAIKey: String?
    public let anthropicKey: String?
    public let geminiKey: String?
    public let openRouterKey: String?
    public let bedrockAccessKeyId: String?
    public let bedrockSecretAccessKey: String?
    public let bedrockRegion: String?

    // Encryption configuration
    public let piiDetectionEnabled: Bool
    public let injectionProtectionEnabled: Bool
    public let piiConfidenceThreshold: Double
    public let piiLLMFallbackEnabled: Bool

    // Web research configuration
    public let webResearchEnabled: Bool
    public let perplexityAPIKey: String?
    public let tavilyAPIKey: String?

    // Audit logging configuration
    public let auditEnabled: Bool
    public let auditLogPath: URL

    // LLM configuration (token limits, temperatures, thresholds)
    public let llm: LLMConfiguration

    public init(
        aiProvider: AIProviderType,
        aiAPIKey: String?,
        aiModel: String?,
        storageType: StorageType,
        storagePath: URL,
        databaseURL: String? = nil,
        licenseTier: LicenseTier = .free,
        licenseResolution: LicenseResolution = .free,
        openAIKey: String? = nil,
        anthropicKey: String? = nil,
        geminiKey: String? = nil,
        openRouterKey: String? = nil,
        bedrockAccessKeyId: String? = nil,
        bedrockSecretAccessKey: String? = nil,
        bedrockRegion: String? = nil,
        piiDetectionEnabled: Bool = true,
        injectionProtectionEnabled: Bool = true,
        piiConfidenceThreshold: Double = 0.7,
        piiLLMFallbackEnabled: Bool = false,
        webResearchEnabled: Bool = false,
        perplexityAPIKey: String? = nil,
        tavilyAPIKey: String? = nil,
        auditEnabled: Bool = false,
        auditLogPath: URL = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".aiprd")
            .appendingPathComponent("audit"),
        llm: LLMConfiguration = .default
    ) {
        self.aiProvider = aiProvider
        self.aiAPIKey = aiAPIKey
        self.aiModel = aiModel
        self.storageType = storageType
        self.storagePath = storagePath
        self.databaseURL = databaseURL

        // RELEASE builds: always resolve license cryptographically — ignore caller-supplied values
        // DEBUG builds: allow injection for testing
        #if DEBUG
        self.licenseTier = licenseTier
        self.licenseResolution = licenseResolution
        #else
        let cryptoResolution = LicenseFactory.resolveLicenseTier()
        self.licenseTier = cryptoResolution.tier
        self.licenseResolution = cryptoResolution
        #endif

        self.openAIKey = openAIKey
        self.anthropicKey = anthropicKey
        self.geminiKey = geminiKey
        self.openRouterKey = openRouterKey
        self.bedrockAccessKeyId = bedrockAccessKeyId
        self.bedrockSecretAccessKey = bedrockSecretAccessKey
        self.bedrockRegion = bedrockRegion
        self.piiDetectionEnabled = piiDetectionEnabled
        self.injectionProtectionEnabled = injectionProtectionEnabled
        self.piiConfidenceThreshold = piiConfidenceThreshold
        self.piiLLMFallbackEnabled = piiLLMFallbackEnabled
        self.webResearchEnabled = webResearchEnabled
        self.perplexityAPIKey = perplexityAPIKey
        self.tavilyAPIKey = tavilyAPIKey
        self.auditEnabled = auditEnabled
        self.auditLogPath = auditLogPath
        self.llm = llm
    }

    /// Default configuration (Apple Intelligence, in-memory storage, free tier)
    /// Use fromEnvironment() for license-aware configuration
    public static let `default` = Configuration(
        aiProvider: .appleFoundationModels,
        aiAPIKey: nil,
        aiModel: nil,
        storageType: .memory,
        storagePath: URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".ai-prd"),
        licenseTier: .free,
        licenseResolution: .free,
        piiDetectionEnabled: true,
        injectionProtectionEnabled: true,
        piiConfidenceThreshold: 0.7,
        piiLLMFallbackEnabled: false,
        webResearchEnabled: false,
        perplexityAPIKey: nil,
        tavilyAPIKey: nil,
        auditEnabled: false,
        llm: .default
    )

    /// Load configuration from environment variables
    public static func fromEnvironment() -> Configuration {
        let providerString = ProcessInfo.processInfo.environment["AI_PROVIDER"] ?? "apple"
        let aiProvider = parseAIProvider(providerString)
        let storage = parseStorageConfiguration()
        let keys = parseAIProviderKeys()
        let resolution = parseLicenseResolution()
        let encryption = parseEncryptionConfiguration()
        let webResearch = parseWebResearchConfiguration()
        let audit = parseAuditConfiguration(securityEnabled: encryption.piiDetectionEnabled || encryption.injectionProtectionEnabled)
        let llm = LLMConfiguration.fromEnvironment()

        return Configuration(
            aiProvider: aiProvider,
            aiAPIKey: keys.primary,
            aiModel: ProcessInfo.processInfo.environment["AI_MODEL"],
            storageType: storage.type,
            storagePath: storage.path,
            databaseURL: storage.databaseURL,
            licenseTier: resolution.tier,
            licenseResolution: resolution,
            openAIKey: keys.openAI,
            anthropicKey: keys.anthropic,
            geminiKey: keys.gemini,
            openRouterKey: keys.openRouter,
            bedrockAccessKeyId: keys.bedrockAccessKeyId,
            bedrockSecretAccessKey: keys.bedrockSecretAccessKey,
            bedrockRegion: keys.bedrockRegion,
            piiDetectionEnabled: encryption.piiDetectionEnabled,
            injectionProtectionEnabled: encryption.injectionProtectionEnabled,
            piiConfidenceThreshold: encryption.piiConfidenceThreshold,
            piiLLMFallbackEnabled: encryption.piiLLMFallbackEnabled,
            webResearchEnabled: webResearch.enabled,
            perplexityAPIKey: webResearch.perplexityKey,
            tavilyAPIKey: webResearch.tavilyKey,
            auditEnabled: audit.enabled,
            auditLogPath: audit.path ?? URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent(".aiprd")
                .appendingPathComponent("audit"),
            llm: llm
        )
    }

    private static func parseWebResearchConfiguration() -> ConfigurationWebResearchConfig {
        let env = ProcessInfo.processInfo.environment
        let perplexityKey = env["PERPLEXITY_API_KEY"]
        let tavilyKey = env["TAVILY_API_KEY"]
        let enabled = env["WEB_RESEARCH_ENABLED"]?.lowercased() == "true" ||
                     perplexityKey != nil || tavilyKey != nil
        return ConfigurationWebResearchConfig(
            perplexityKey: perplexityKey,
            tavilyKey: tavilyKey,
            enabled: enabled
        )
    }

    private static func parseAuditConfiguration(securityEnabled: Bool) -> ConfigurationAuditConfig {
        let env = ProcessInfo.processInfo.environment
        let explicitValue = env["AUDIT_ENABLED"]?.lowercased()
        let enabled: Bool
        if let explicit = explicitValue {
            enabled = explicit == "true" || explicit == "1" || explicit == "yes"
        } else {
            // Default: enabled when security features are on
            enabled = securityEnabled
        }
        let path = env["AUDIT_LOG_PATH"].map { URL(fileURLWithPath: $0) }
        return ConfigurationAuditConfig(enabled: enabled, path: path)
    }

    private static func parseEncryptionConfiguration() -> ConfigurationEncryptionConfig {
        let env = ProcessInfo.processInfo.environment
        return ConfigurationEncryptionConfig(
            piiDetectionEnabled: env["PII_DETECTION_ENABLED"]?.lowercased() != "false",
            injectionProtectionEnabled: env["INJECTION_PROTECTION_ENABLED"]?.lowercased() != "false",
            piiConfidenceThreshold: Double(env["PII_CONFIDENCE_THRESHOLD"] ?? "") ?? 0.7,
            piiLLMFallbackEnabled: env["PII_LLM_FALLBACK_ENABLED"]?.lowercased() == "true"
        )
    }

    private static func parseLicenseResolution() -> LicenseResolution {
        // Use cryptographic license validation via LicenseFactory
        // Priority: env override (DEBUG) > signed license file > trial > free
        return LicenseFactory.resolveLicenseTier()
    }

    private static func parseStorageConfiguration() -> ConfigurationStorageConfig {
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

        return ConfigurationStorageConfig(
            type: storageType,
            path: storagePath,
            databaseURL: databaseURL
        )
    }

    private static func parseAIProviderKeys() -> ConfigurationAIProviderKeys {
        let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        let anthropicKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        let geminiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
        let openRouterKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
        let bedrockAccessKeyId = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"]
        let bedrockSecretAccessKey = ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"]
        let bedrockRegion = ProcessInfo.processInfo.environment["AWS_REGION"]
        let primaryKey = openAIKey ?? anthropicKey ?? geminiKey
        return ConfigurationAIProviderKeys(
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
        case "openrouter":
            return .openRouter
        case "bedrock", "aws":
            return .bedrock
        case "qwen", "tongyi", "dashscope":
            return .qwen
        case "zhipu", "glm", "chatglm":
            return .zhipu
        case "moonshot", "kimi":
            return .moonshot
        case "minimax":
            return .minimax
        case "deepseek":
            return .deepseek
        default:
            return .appleFoundationModels
        }
    }
}
