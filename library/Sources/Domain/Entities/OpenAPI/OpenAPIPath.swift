import Foundation

/// OpenAPI path operations
/// Following Single Responsibility Principle - represents path operations
public struct OpenAPIPath: Sendable, Codable {
    public let get: OpenAPIOperation?
    public let post: OpenAPIOperation?
    public let put: OpenAPIOperation?
    public let delete: OpenAPIOperation?
    public let patch: OpenAPIOperation?

    public init(
        get: OpenAPIOperation? = nil,
        post: OpenAPIOperation? = nil,
        put: OpenAPIOperation? = nil,
        delete: OpenAPIOperation? = nil,
        patch: OpenAPIOperation? = nil
    ) {
        self.get = get
        self.post = post
        self.put = put
        self.delete = delete
        self.patch = patch
    }
}
