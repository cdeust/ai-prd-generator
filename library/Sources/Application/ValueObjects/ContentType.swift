import Foundation

/// Content type for chunking selection
public enum ContentType: Sendable {
    case naturalText
    case structuredDocument
    case sourceCode
    case embedding
}
