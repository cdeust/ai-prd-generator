import Foundation

/// OpenAPI response
/// Following Single Responsibility Principle - represents API response specification
public struct OpenAPIResponse: Sendable, Codable {
    public let description: String
    public let content: [String: OpenAPIMediaType]?

    public init(
        description: String,
        content: [String: OpenAPIMediaType]? = nil
    ) {
        self.description = description
        self.content = content
    }
}
