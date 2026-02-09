import Foundation

/// Internal struct for encryption configuration parsing
struct ConfigurationEncryptionConfig {
    let piiDetectionEnabled: Bool
    let injectionProtectionEnabled: Bool
    let piiConfidenceThreshold: Double
    let piiLLMFallbackEnabled: Bool
}
