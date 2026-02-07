import AIPRDSharedUtilities
import Foundation

/// Diagnostics information about context window detection
public struct ContextWindowDiagnostics: Sendable {
    public let currentEstimate: Int
    public let failureCount: Int
    public let lastKnownLimit: Int?
}
