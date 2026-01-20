import Foundation

/// Port for Session persistence
/// Domain defines the interface, Infrastructure implements it
/// Following Interface Segregation Principle - focused interface
public protocol SessionRepositoryPort: Sendable {
    /// Create a new session
    func create(_ session: Session) async throws -> Session

    /// Find session by ID
    func findById(_ id: UUID) async throws -> Session?

    /// Find all sessions
    func findAll() async throws -> [Session]

    /// Update existing session
    func update(_ session: Session) async throws -> Session

    /// Delete session
    func delete(_ id: UUID) async throws

    /// Find active sessions
    func findActive() async throws -> [Session]

    /// Add message to session
    func addMessage(
        _ message: ChatMessage,
        to sessionId: UUID
    ) async throws -> ChatMessage

    /// Get messages for session
    func getMessages(
        for sessionId: UUID,
        limit: Int
    ) async throws -> [ChatMessage]
}
