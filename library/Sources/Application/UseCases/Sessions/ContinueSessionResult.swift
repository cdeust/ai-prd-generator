import Foundation
import Domain

/// Result of continuing a session with new message
public struct ContinueSessionResult: Sendable {
    public let session: Session
    public let document: PRDDocument
    public let message: ChatMessage

    public init(session: Session, document: PRDDocument, message: ChatMessage) {
        self.session = session
        self.document = document
        self.message = message
    }
}
