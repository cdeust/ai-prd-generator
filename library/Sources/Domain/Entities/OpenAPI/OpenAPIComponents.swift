import Foundation

/// OpenAPI components (schemas, security)
/// Following Single Responsibility Principle - represents reusable components
public struct OpenAPIComponents: Sendable, Codable {
    public let schemas: [String: String]
    public let securitySchemes: [String: OpenAPISecurityScheme]

    public init(
        schemas: [String: String] = [:],
        securitySchemes: [String: OpenAPISecurityScheme] = [:]
    ) {
        self.schemas = schemas
        self.securitySchemes = securitySchemes
    }
}
