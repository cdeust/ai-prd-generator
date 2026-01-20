import Foundation

/// Port for orchestrating AI workflows
/// Domain defines the interface, Application implements
public protocol OrchestrationPort: Sendable {
    /// Process a prompt through the AI workflow
    func process(prompt: String) async throws -> String

    /// Validate AI response
    func validate(response: String) async throws -> ValidationResult
}
