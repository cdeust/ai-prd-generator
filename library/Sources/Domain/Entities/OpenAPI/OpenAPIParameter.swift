import Foundation

/// OpenAPI parameter
/// Following Single Responsibility Principle - represents operation parameter
public struct OpenAPIParameter: Sendable, Codable {
    public let name: String
    public let location: ParameterLocation
    public let description: String
    public let required: Bool
    public let schema: String

    public init(
        name: String,
        location: ParameterLocation,
        description: String,
        required: Bool,
        schema: String
    ) {
        self.name = name
        self.location = location
        self.description = description
        self.required = required
        self.schema = schema
    }
}
