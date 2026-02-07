import Foundation

/// Errors from web research providers
public enum WebResearchError: Error, Sendable {
    case networkError(String)
    case apiError(String)
    case parseError(String)
    case rateLimited
    case notConfigured
}
