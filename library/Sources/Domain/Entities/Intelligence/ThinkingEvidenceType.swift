import Foundation

/// Type of evidence used in thinking chain reasoning
public enum ThinkingEvidenceType: String, Sendable, Codable, CaseIterable {
    case ragChunk = "rag_chunk"
    case mockup = "mockup"
    case clarification = "clarification"
    case previousSection = "previous_section"
    case userInput = "user_input"
}
