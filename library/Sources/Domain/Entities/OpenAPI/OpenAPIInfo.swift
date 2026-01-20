import Foundation

/// OpenAPI info metadata
/// Following Single Responsibility Principle - represents API info section
public struct OpenAPIInfo: Sendable, Codable {
    public let title: String
    public let description: String
    public let version: String
    public let contact: OpenAPIContact?

    public init(
        title: String,
        description: String,
        version: String,
        contact: OpenAPIContact? = nil
    ) {
        self.title = title
        self.description = description
        self.version = version
        self.contact = contact
    }
}
