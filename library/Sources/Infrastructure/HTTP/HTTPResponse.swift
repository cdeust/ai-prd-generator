import AIPRDSharedUtilities
import Foundation

/// HTTP Response representation
/// Value object for HTTP responses
public struct HTTPResponse {
    public let statusCode: Int
    public let headers: [String: String]
    public let data: Data

    public init(statusCode: Int, headers: [String: String], data: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = data
    }

    public var isSuccess: Bool {
        (200..<300).contains(statusCode)
    }
}
