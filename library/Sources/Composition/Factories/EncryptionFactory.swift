import AIPRDOrchestrationEngine
import AIPRDEncryptionEngine
import AIPRDSharedUtilities
import Foundation

/// Factory for creating the encryption/security engine
public struct EncryptionFactory: Sendable {
    private let configuration: Configuration

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func createEncryptionEngine(
        aiProvider: AIProviderPort? = nil
    ) -> EncryptionEngineResult {
        let encryptionConfig = EncryptionConfiguration(
            piiDetectionEnabled: configuration.piiDetectionEnabled,
            injectionProtectionEnabled: configuration.injectionProtectionEnabled,
            piiConfidenceThreshold: configuration.piiConfidenceThreshold,
            piiLLMFallbackEnabled: configuration.piiLLMFallbackEnabled
        )

        let engine = EncryptionEngine(
            configuration: encryptionConfig,
            aiProvider: encryptionConfig.piiLLMFallbackEnabled ? aiProvider : nil
        )

        if encryptionConfig.piiDetectionEnabled || encryptionConfig.injectionProtectionEnabled {
            print("🔒 [EncryptionFactory] EncryptionEngine created (PII: \(encryptionConfig.piiDetectionEnabled), Injection: \(encryptionConfig.injectionProtectionEnabled))")
            return .engine(engine)
        } else {
            print("⚠️ [EncryptionFactory] EncryptionEngine degraded (all protections disabled)")
            return .degraded
        }
    }
}
