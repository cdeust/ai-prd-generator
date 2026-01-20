import Foundation
import Domain

/// Supabase Client for API communication
/// Single Responsibility: Supabase REST API authentication and request handling
/// Following naming convention: {Technology}Client
public final class SupabaseClient: Sendable {
    // MARK: - Properties

    private let projectURL: URL
    private let apiKey: String
    private let httpClient: HTTPClient

    // MARK: - Initialization

    public init(
        projectURL: URL,
        apiKey: String,
        httpClient: HTTPClient = HTTPClient()
    ) {
        self.projectURL = projectURL
        self.apiKey = apiKey
        self.httpClient = httpClient
    }

    // MARK: - Public Methods

    /// Execute authenticated Supabase request
    public func execute<T: Decodable>(
        method: HTTPMethod,
        path: String,
        body: Data? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        let response = try await executeRaw(
            method: method,
            path: path,
            body: body,
            queryItems: queryItems
        )

        return try decodeResponse(response.data)
    }

    /// Execute request without decoding response
    public func executeRaw(
        method: HTTPMethod,
        path: String,
        body: Data? = nil,
        queryItems: [URLQueryItem] = [],
        additionalHeaders: [String: String] = [:]
    ) async throws -> HTTPResponse {
        let url = try buildURL(path: path, queryItems: queryItems)
        var headers = buildHeaders()

        // Merge additional headers (override defaults if needed)
        for (key, value) in additionalHeaders {
            headers[key] = value
        }

        let request = HTTPRequest(
            url: url,
            method: method,
            headers: headers,
            body: body
        )

        let response = try await httpClient.execute(request)
        try validateResponse(response)

        return response
    }

    // MARK: - Private Methods

    private func buildURL(
        path: String,
        queryItems: [URLQueryItem]
    ) throws -> URL {
        var components = URLComponents(
            url: projectURL,
            resolvingAgainstBaseURL: false
        )

        components?.path = "/rest/v1" + path

        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw SupabaseError.invalidURL(path)
        }

        return url
    }

    private func buildHeaders() -> [String: String] {
        [
            "apikey": apiKey,
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        ]
    }

    private func validateResponse(_ response: HTTPResponse) throws {
        guard (200...299).contains(response.statusCode) else {
            try handleErrorResponse(response)
        }
    }

    private func handleErrorResponse(_ response: HTTPResponse) throws -> Never {
        if let errorData = try? JSONDecoder().decode(
            SupabaseErrorResponse.self,
            from: response.data
        ) {
            throw SupabaseError.apiError(
                code: errorData.code ?? "unknown",
                message: errorData.message
            )
        }

        throw SupabaseError.httpError(
            statusCode: response.statusCode,
            data: response.data
        )
    }

    private func decodeResponse<T: Decodable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SupabaseError.decodingFailed(error)
        }
    }
}
