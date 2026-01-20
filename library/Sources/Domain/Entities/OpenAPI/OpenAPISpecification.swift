import Foundation

/// OpenAPI specification entity
/// Following Single Responsibility Principle - represents OpenAPI specification
public struct OpenAPISpecification: Identifiable, Sendable, Codable {
    public let id: UUID
    public let version: String
    public let info: OpenAPIInfo
    public let paths: [String: OpenAPIPath]
    public let components: OpenAPIComponents
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        version: String = "3.1.0",
        info: OpenAPIInfo,
        paths: [String: OpenAPIPath],
        components: OpenAPIComponents = OpenAPIComponents(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.version = version
        self.info = info
        self.paths = paths
        self.components = components
        self.createdAt = createdAt
    }
}
