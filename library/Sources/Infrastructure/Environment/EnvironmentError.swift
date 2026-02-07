import AIPRDSharedUtilities
import Foundation

/// Environment configuration errors
public enum EnvironmentError: Error, Sendable {
    case missingRequiredKey(String)
    case fileNotFound(String)
}
