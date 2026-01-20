import Foundation

/// OpenAPI media type
/// Following Single Responsibility Principle - represents content media type
public struct OpenAPIMediaType: Sendable, Codable {
    public let schema: String
    public let example: String?

    public init(schema: String, example: String? = nil) {
        self.schema = schema
        self.example = example
    }
}
