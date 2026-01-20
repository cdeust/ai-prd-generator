import Foundation

/// OpenAPI parameter location
/// Following Single Responsibility Principle - represents parameter location in API
public enum ParameterLocation: String, Sendable, Codable {
    case query
    case header
    case path
    case cookie
}
