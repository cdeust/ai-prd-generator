import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation

/// Use case for continuing a session with new message
/// Following SRP - handles conversational PRD generation
/// Following DIP - depends on repository ports
public struct ContinueSessionUseCase: Sendable {
    private let sessionRepository: SessionRepositoryPort
    private let generatePRD: GeneratePRDUseCase

    public init(
        sessionRepository: SessionRepositoryPort,
        generatePRD: GeneratePRDUseCase
    ) {
        self.sessionRepository = sessionRepository
        self.generatePRD = generatePRD
    }

    public func execute(
        sessionId: UUID,
        userMessage: String,
        onChunk: @escaping (String) async throws -> Void = { _ in },
        onProgress: @escaping (String) async throws -> Void = { _ in }
    ) async throws -> ContinueSessionResult {
        guard var session = try await sessionRepository.findById(sessionId) else {
            throw ValidationError.custom("Session not found: \(sessionId)")
        }

        let userMsg = ChatMessage(role: .user, content: userMessage, timestamp: Date())
        _ = try await sessionRepository.addMessage(userMsg, to: sessionId)
        session.messages.append(userMsg)

        let context = buildContext(from: session)
        let intent = analyzeIntent(message: userMessage, session: session)
        let document = try await generateDocument(
            intent: intent,
            session: session,
            context: context,
            onChunk: onChunk,
            onProgress: onProgress
        )

        let assistantMsg = ChatMessage(
            role: .assistant,
            content: formatPRDResponse(document),
            timestamp: Date()
        )
        _ = try await sessionRepository.addMessage(assistantMsg, to: sessionId)
        session = try await sessionRepository.update(session)

        return ContinueSessionResult(session: session, document: document, message: assistantMsg)
    }

    private func generateDocument(
        intent: MessageIntent,
        session: Session,
        context: String,
        onChunk: @escaping (String) async throws -> Void,
        onProgress: @escaping (String) async throws -> Void
    ) async throws -> PRDDocument {
        switch intent {
        case .newPRD(let title, let description):
            let request = PRDRequest(
                userId: session.userId,
                title: title,
                description: buildDescriptionWithContext(description, context: context)
            )
            return try await generatePRD.execute(request, onChunk: onChunk, onProgress: onProgress)

        case .refinePRD(let instructions):
            let request = PRDRequest(
                userId: session.userId,
                title: "Refined PRD",
                description: buildDescriptionWithContext(instructions, context: context)
            )
            return try await generatePRD.execute(request, onChunk: onChunk, onProgress: onProgress)
        }
    }

    private func buildContext(from session: Session) -> String {
        let recentMessages = Array(session.messages.suffix(10))
        return recentMessages
            .map { "[\($0.role.rawValue)]: \($0.content)" }
            .joined(separator: "\n\n")
    }

    private func analyzeIntent(
        message: String,
        session: Session
    ) -> MessageIntent {
        let lower = message.lowercased()

        if lower.contains("make") || lower.contains("add") ||
           lower.contains("change") || lower.contains("update") ||
           lower.contains("refine") || lower.contains("improve") {
            return .refinePRD(instructions: message)
        }

        if lower.contains("generate") || lower.contains("create") ||
           session.messages.count <= 1 {
            let title = extractTitle(from: message)
            let description = extractDescription(from: message)
            return .newPRD(title: title, description: description)
        }

        return .refinePRD(instructions: message)
    }

    private func extractTitle(from message: String) -> String {
        if message.lowercased().contains("prd for") {
            let parts = message.components(separatedBy: "prd for")
            if parts.count > 1 {
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
        }

        return message.prefix(50).trimmingCharacters(in: .whitespaces)
    }

    private func extractDescription(from message: String) -> String {
        return message
    }

    private func buildDescriptionWithContext(
        _ description: String,
        context: String
    ) -> String {
        if context.isEmpty {
            return description
        }

        return """
        \(description)

        Context from conversation:
        \(context)
        """
    }

    private func formatPRDResponse(_ document: PRDDocument) -> String {
        return """
        PRD Generated:
        ID: \(document.id)
        Title: \(document.title)
        Version: \(document.version)
        Sections: \(document.sections.count)
        """
    }
}
