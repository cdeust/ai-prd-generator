import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// In-memory implementation of SessionRepositoryPort
/// For testing, demos, and rapid prototyping
/// Thread-safe using actor isolation
public actor InMemorySessionRepository: SessionRepositoryPort {
    private var sessions: [UUID: Session] = [:]
    private var messages: [UUID: [ChatMessage]] = [:]
    private let defaultUserId: UUID

    public init(defaultUserId: UUID = UUID()) {
        self.defaultUserId = defaultUserId
    }

    public func create(_ session: Session) async throws -> Session {
        sessions[session.id] = session
        messages[session.id] = []
        return session
    }

    public func findById(_ id: UUID) async throws -> Session? {
        guard var session = sessions[id] else {
            return nil
        }

        session.messages = messages[id] ?? []
        return session
    }

    public func findAll() async throws -> [Session] {
        let allSessions = sessions.values.sorted { $0.startTime > $1.startTime }

        return allSessions.map { session in
            var updatedSession = session
            updatedSession.messages = messages[session.id] ?? []
            return updatedSession
        }
    }

    public func update(_ session: Session) async throws -> Session {
        guard sessions[session.id] != nil else {
            throw RepositoryError.invalidQuery("Session not found: \(session.id)")
        }

        sessions[session.id] = session
        return session
    }

    public func delete(_ id: UUID) async throws {
        guard sessions[id] != nil else {
            throw RepositoryError.invalidQuery("Session not found: \(id)")
        }

        sessions.removeValue(forKey: id)
        messages.removeValue(forKey: id)
    }

    public func findActive() async throws -> [Session] {
        let activeSessions = sessions.values
            .filter { $0.metadata.isActive }
            .sorted { $0.startTime > $1.startTime }

        return activeSessions.map { session in
            var updatedSession = session
            updatedSession.messages = messages[session.id] ?? []
            return updatedSession
        }
    }

    public func addMessage(
        _ message: ChatMessage,
        to sessionId: UUID
    ) async throws -> ChatMessage {
        guard sessions[sessionId] != nil else {
            throw RepositoryError.invalidQuery("Session not found: \(sessionId)")
        }

        messages[sessionId, default: []].append(message)
        return message
    }

    public func getMessages(
        for sessionId: UUID,
        limit: Int
    ) async throws -> [ChatMessage] {
        let sessionMessages = messages[sessionId] ?? []
        return Array(sessionMessages.suffix(limit))
    }
}
