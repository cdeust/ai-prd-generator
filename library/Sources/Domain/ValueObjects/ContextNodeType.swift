import Foundation

/// Type of context node in graph
/// Following Single Responsibility: Classifies context nodes
public enum ContextNodeType: Equatable, Sendable {
    case codeChunk(filePath: String)
    case thought(thoughtType: ThoughtType)
    case assumption
    case inference
    case evidence
    case question
    case conclusion
    case externalReference
}
