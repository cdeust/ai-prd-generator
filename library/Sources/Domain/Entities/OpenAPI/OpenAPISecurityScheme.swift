import Foundation

/// OpenAPI security scheme
/// Following Single Responsibility Principle - represents security scheme configuration
public struct OpenAPISecurityScheme: Sendable, Codable {
    public let type: String
    public let scheme: String?
    public let bearerFormat: String?

    public init(type: String, scheme: String? = nil, bearerFormat: String? = nil) {
        self.type = type
        self.scheme = scheme
        self.bearerFormat = bearerFormat
    }
}
