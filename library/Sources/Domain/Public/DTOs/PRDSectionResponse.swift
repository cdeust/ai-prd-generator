import Foundation

/// Public PRD section response
/// Public DTO for PRD section data
public struct PRDSectionResponse: Sendable {
    public let type: String
    public let content: String

    public init(type: String, content: String) {
        self.type = type
        self.content = content
    }
}
