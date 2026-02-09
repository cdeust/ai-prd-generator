import AIPRDSharedUtilities
import Foundation

/// Configuration errors for standalone skill
public enum ConfigurationError: Error, Sendable {
    case missingAPIKey(String)
    case missingDatabaseURL
}
