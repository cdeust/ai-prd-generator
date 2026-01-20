import Foundation

/// OpenAPI contact information
/// Following Single Responsibility Principle - represents contact details
public struct OpenAPIContact: Sendable, Codable {
    public let name: String
    public let email: String?
    public let url: String?

    public init(name: String, email: String? = nil, url: String? = nil) {
        self.name = name
        self.email = email
        self.url = url
    }
}
