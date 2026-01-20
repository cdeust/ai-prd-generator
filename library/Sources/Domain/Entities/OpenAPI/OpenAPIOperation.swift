import Foundation

/// OpenAPI operation (endpoint)
/// Following Single Responsibility Principle - represents single API operation
public struct OpenAPIOperation: Sendable, Codable {
    public let summary: String
    public let description: String
    public let operationId: String
    public let parameters: [OpenAPIParameter]
    public let requestBody: OpenAPIRequestBody?
    public let responses: [String: OpenAPIResponse]

    public init(
        summary: String,
        description: String,
        operationId: String,
        parameters: [OpenAPIParameter] = [],
        requestBody: OpenAPIRequestBody? = nil,
        responses: [String: OpenAPIResponse]
    ) {
        self.summary = summary
        self.description = description
        self.operationId = operationId
        self.parameters = parameters
        self.requestBody = requestBody
        self.responses = responses
    }
}
