import Foundation

/// Configuration errors
public enum ConfigurationError: Error, Sendable {
    case missingAPIKey(String)
    case missingSupabaseCredentials
    case missingDatabaseURL
}
