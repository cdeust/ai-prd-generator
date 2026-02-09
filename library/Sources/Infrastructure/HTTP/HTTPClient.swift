import AIPRDSharedUtilities
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// HTTP Client for REST API calls
/// Single Responsibility: HTTP request/response handling
/// Following naming convention: {Purpose}Client
public final class HTTPClient: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Create HTTPClient configured for long-running operations (e.g., repository indexing)
    /// Timeouts are read from environment variables, defaulting to no timeout if not set
    public static func longRunning() -> HTTPClient {
        let configuration = URLSessionConfiguration.default

        // Read timeouts from environment, use max value (no timeout) if not configured
        let requestTimeout = ProcessInfo.processInfo.environment["HTTP_REQUEST_TIMEOUT_SECONDS"]
            .flatMap { TimeInterval($0) } ?? TimeInterval.greatestFiniteMagnitude
        let resourceTimeout = ProcessInfo.processInfo.environment["HTTP_RESOURCE_TIMEOUT_SECONDS"]
            .flatMap { TimeInterval($0) } ?? TimeInterval.greatestFiniteMagnitude

        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = resourceTimeout

        // waitsForConnectivity is read-only on Linux
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        configuration.waitsForConnectivity = true
        #endif

        let session = URLSession(configuration: configuration)
        return HTTPClient(session: session)
    }

    /// Execute HTTP request
    public func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
        let urlRequest = try buildURLRequest(from: request)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }

        return HTTPResponse(
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
            data: data
        )
    }

    private func buildURLRequest(from request: HTTPRequest) throws -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let timeout = request.timeout {
            urlRequest.timeoutInterval = timeout
        }

        return urlRequest
    }
}
