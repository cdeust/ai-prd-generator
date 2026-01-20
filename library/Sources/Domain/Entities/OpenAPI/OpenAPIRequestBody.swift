import Foundation

/// OpenAPI request body
/// Following Single Responsibility Principle - represents request body specification
public struct OpenAPIRequestBody: Sendable, Codable {
    public let description: String
    public let required: Bool
    public let content: [String: OpenAPIMediaType]

    public init(
        description: String,
        required: Bool,
        content: [String: OpenAPIMediaType]
    ) {
        self.description = description
        self.required = required
        self.content = content
    }
}
