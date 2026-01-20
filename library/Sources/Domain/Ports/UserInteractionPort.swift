import Foundation

/// Port for interacting with users during PRD generation
///
/// Allows GeneratePRDUseCase to ask clarification questions reactively.
public protocol UserInteractionPort: Sendable {
    /// Ask a clarification question and get user's answer
    ///
    /// - Parameter question: The clarification question to ask
    /// - Returns: User's answer or nil if skipped
    func askQuestion(_ question: ClarificationQuestion<String, Int, String>) async -> String?

    /// Notify user of analysis progress
    ///
    /// - Parameter message: Progress message
    func notifyProgress(_ message: String) async
}
