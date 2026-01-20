import Foundation

/// Port for debug logging
/// Domain defines the interface, Infrastructure implements
public protocol DebugLoggerPort: Sendable {
    /// Print debug message only if DEBUG is enabled
    func debug(_ message: String)

    /// Print debug message with custom prefix
    func debug(_ message: String, prefix: String)

    /// Print AI response with provider info
    func aiResponse(_ response: String, provider: String)

    /// Always print important messages
    func always(_ message: String)

    /// Check if debug mode is enabled
    var isDebugEnabled: Bool { get }
}
