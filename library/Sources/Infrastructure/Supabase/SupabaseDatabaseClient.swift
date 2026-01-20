import Foundation
import Domain

/// Supabase Database Client - Implementation of SupabaseDatabasePort
/// Single Responsibility: Supabase database operations (CRUD)
/// Following naming: Supabase{Purpose}Client
public final class SupabaseDatabaseClient: SupabaseDatabasePort, Sendable {
    private let supabaseClient: SupabaseClient

    public init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }

    public func select(
        from table: String,
        columns: [String]?,
        filter: QueryFilter?
    ) async throws -> Data {
        var queryItems: [URLQueryItem] = []

        if let columns = columns {
            queryItems.append(
                URLQueryItem(
                    name: "select",
                    value: columns.joined(separator: ",")
                )
            )
        }

        if let filter = filter {
            queryItems.append(contentsOf: buildFilterQuery(filter))
        }

        let response: HTTPResponse = try await supabaseClient.executeRaw(
            method: .get,
            path: "/\(table)",
            queryItems: queryItems
        )

        return response.data
    }

    public func insert<T: Encodable>(
        table: String,
        values: T
    ) async throws -> Data {
        // Note: Don't use .convertToSnakeCase - DTOs have explicit CodingKeys
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(values)

        let response: HTTPResponse = try await supabaseClient.executeRaw(
            method: .post,
            path: "/\(table)",
            body: body
        )

        return response.data
    }

    public func upsert<T: Encodable>(
        table: String,
        values: T,
        onConflict columns: [String]
    ) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(values)

        let queryItems = [
            URLQueryItem(name: "on_conflict", value: columns.joined(separator: ","))
        ]

        let response: HTTPResponse = try await supabaseClient.executeRaw(
            method: .post,
            path: "/\(table)",
            body: body,
            queryItems: queryItems,
            additionalHeaders: ["Prefer": "resolution=merge-duplicates,return=representation"]
        )

        return response.data
    }

    public func update<T: Encodable>(
        table: String,
        values: T,
        matching filter: QueryFilter
    ) async throws -> Data {
        // Note: Don't use .convertToSnakeCase - DTOs have explicit CodingKeys
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(values)
        let queryItems = buildFilterQuery(filter)

        let response: HTTPResponse = try await supabaseClient.executeRaw(
            method: .patch,
            path: "/\(table)",
            body: body,
            queryItems: queryItems
        )

        return response.data
    }

    public func delete(
        from table: String,
        matching filter: QueryFilter
    ) async throws {
        let queryItems = buildFilterQuery(filter)

        let _: HTTPResponse = try await supabaseClient.executeRaw(
            method: .delete,
            path: "/\(table)",
            queryItems: queryItems
        )
    }

    public func insertBatch<T: Encodable>(
        table: String,
        values: [T]
    ) async throws -> Data {
        // Note: Don't use .convertToSnakeCase - DTOs have explicit CodingKeys
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(values)

        let response: HTTPResponse = try await supabaseClient.executeRaw(
            method: .post,
            path: "/\(table)",
            body: body
        )

        return response.data
    }

    public func count(
        from table: String,
        filter: QueryFilter?
    ) async throws -> Int {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "count")
        ]

        if let filter = filter {
            queryItems.append(contentsOf: buildFilterQuery(filter))
        }

        let response: HTTPResponse = try await supabaseClient.executeRaw(
            method: .get,
            path: "/\(table)",
            queryItems: queryItems
        )

        let decoder = JSONDecoder()
        let result = try decoder.decode(
            [SupabaseCountResult].self,
            from: response.data
        )
        return result.first?.count ?? 0
    }

    public func callRPC(
        function: String,
        parameters: [String: Any]
    ) async throws -> Data {
        let body = try JSONSerialization.data(withJSONObject: parameters)

        let response: HTTPResponse = try await supabaseClient.executeRaw(
            method: .post,
            path: "/rpc/\(function)",
            body: body
        )

        return response.data
    }

    public func callRPC<T: Decodable>(
        function: String,
        parameters: [String: Any],
        responseType: T.Type
    ) async throws -> T {
        let data = try await callRPC(function: function, parameters: parameters)

        // Note: Don't use .convertFromSnakeCase - DTOs have explicit CodingKeys
        let decoder = JSONDecoder()
        return try decoder.decode(responseType, from: data)
    }

    // MARK: - Private Methods

    private func buildFilterQuery(_ filter: QueryFilter) -> [URLQueryItem] {
        let operatorString = filterOperationString(filter.operation)
        let queryValue = "\(operatorString).\(filter.value)"

        return [URLQueryItem(name: filter.field, value: queryValue)]
    }

    private func filterOperationString(_ operation: FilterOperation) -> String {
        switch operation {
        case .equals:
            return "eq"
        case .notEquals:
            return "neq"
        case .greaterThan:
            return "gt"
        case .greaterThanOrEqual:
            return "gte"
        case .lessThan:
            return "lt"
        case .lessThanOrEqual:
            return "lte"
        case .like:
            return "like"
        case .ilike:
            return "ilike"
        case .in:
            return "in"
        case .contains:
            return "cs"
        case .containedBy:
            return "cd"
        }
    }
}
