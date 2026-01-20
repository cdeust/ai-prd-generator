import Foundation
import Domain

/// Supabase repository connection repository
/// Implements RepositoryConnectionPort for Supabase backend
public final class SupabaseRepositoryConnectionRepository: RepositoryConnectionPort, Sendable {
    private let client: SupabaseDatabasePort
    private let tableName = "repository_connections"

    public init(client: SupabaseDatabasePort) {
        self.client = client
    }

    public func saveConnection(_ connection: RepositoryConnection) async throws -> RepositoryConnection {
        // Check if connection already exists for this provider user
        if let existing = try await findConnectionByProviderUserId(
            providerUserId: connection.providerUserId,
            provider: connection.provider
        ) {
            // Update existing connection with new token
            try await updateToken(
                connectionId: existing.id,
                accessToken: connection.accessToken,
                refreshToken: connection.refreshToken,
                expiresAt: connection.expiresAt
            )
            // Return existing connection with updated ID
            return RepositoryConnection(
                id: existing.id,
                userId: existing.userId,
                provider: connection.provider,
                accessToken: connection.accessToken,
                refreshToken: connection.refreshToken,
                scopes: connection.scopes,
                providerUserId: connection.providerUserId,
                providerUsername: connection.providerUsername,
                connectedAt: existing.connectedAt,
                expiresAt: connection.expiresAt,
                lastSyncedAt: existing.lastSyncedAt
            )
        }

        let row = RepositoryConnectionRow(
            id: connection.id.uuidString,
            userId: connection.userId.uuidString,
            provider: connection.provider.rawValue,
            accessTokenEncrypted: connection.accessToken,
            refreshTokenEncrypted: connection.refreshToken,
            scopes: connection.scopes,
            providerUserId: connection.providerUserId,
            providerUsername: connection.providerUsername,
            connectedAt: connection.connectedAt,
            expiresAt: connection.expiresAt,
            lastSyncedAt: connection.lastSyncedAt
        )

        _ = try await client.insert(table: tableName, values: row)

        return connection
    }

    public func findConnection(id: UUID) async throws -> RepositoryConnection? {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: id.uuidString
        )

        let data = try await client.select(
            from: tableName,
            columns: nil,
            filter: filter
        )

        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let row = rows.first else {
            return nil
        }

        return try parseConnection(row)
    }

    public func findConnections(
        userId: UUID,
        provider: RepositoryProvider?
    ) async throws -> [RepositoryConnection] {
        let filter = QueryFilter(
            field: "user_id",
            operation: .equals,
            value: userId.uuidString
        )

        let data = try await client.select(
            from: tableName,
            columns: nil,
            filter: filter
        )

        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        let connections = rows.compactMap { try? parseConnection($0) }

        if let provider = provider {
            return connections.filter { $0.provider == provider }
        }

        return connections
    }

    public func findConnectionByProviderUserId(
        providerUserId: String,
        provider: RepositoryProvider
    ) async throws -> RepositoryConnection? {
        // Use provider_user_id filter
        let filter = QueryFilter(
            field: "provider_user_id",
            operation: .equals,
            value: providerUserId
        )

        let data = try await client.select(
            from: tableName,
            columns: nil,
            filter: filter
        )

        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            // Log actual data for debugging
            let dataString = String(data: data, encoding: .utf8) ?? "non-utf8 data"
            print("[RepositoryConnection] Failed to parse JSON from: \(dataString.prefix(500))")
            return nil
        }

        // Filter by provider in memory (Supabase single filter limitation)
        var connections: [RepositoryConnection] = []
        for row in rows {
            do {
                let connection = try parseConnection(row)
                connections.append(connection)
            } catch {
                print("[RepositoryConnection] Failed to parse row: \(error), row keys: \(row.keys)")
            }
        }
        return connections.first { $0.provider == provider }
    }

    public func deleteConnection(id: UUID) async throws {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: id.uuidString
        )

        try await client.delete(from: tableName, matching: filter)
    }

    public func updateLastSync(connectionId: UUID, date: Date) async throws {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: connectionId.uuidString
        )

        let update = RepositoryConnectionLastSyncUpdate(lastSyncedAt: date)

        _ = try await client.update(
            table: tableName,
            values: update,
            matching: filter
        )
    }

    public func updateToken(
        connectionId: UUID,
        accessToken: String,
        refreshToken: String?,
        expiresAt: Date?
    ) async throws {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: connectionId.uuidString
        )

        let update = RepositoryConnectionTokenUpdate(
            accessTokenEncrypted: accessToken,
            refreshTokenEncrypted: refreshToken,
            expiresAt: expiresAt
        )

        _ = try await client.update(
            table: tableName,
            values: update,
            matching: filter
        )
    }

    public func updateUserId(connectionId: UUID, userId: UUID) async throws {
        let filter = QueryFilter(
            field: "id",
            operation: .equals,
            value: connectionId.uuidString
        )

        let update = RepositoryConnectionUserIdUpdate(userId: userId.uuidString)

        _ = try await client.update(
            table: tableName,
            values: update,
            matching: filter
        )
    }

    private func parseConnection(_ row: [String: Any]) throws -> RepositoryConnection {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let userIdString = row["user_id"] as? String,
              let userId = UUID(uuidString: userIdString),
              let providerString = row["provider"] as? String,
              let provider = RepositoryProvider(rawValue: providerString),
              let accessToken = row["access_token_encrypted"] as? String,
              let scopes = row["scopes"] as? [String],
              let providerUserId = row["provider_user_id"] as? String,
              let providerUsername = row["provider_username"] as? String,
              let connectedAtString = row["connected_at"] as? String,
              let connectedAt = ISO8601DateFormatter().date(from: connectedAtString) else {
            throw RepositoryError.invalidQuery("Invalid connection data")
        }

        let refreshToken = row["refresh_token_encrypted"] as? String

        let expiresAt: Date? = (row["expires_at"] as? String).flatMap {
            ISO8601DateFormatter().date(from: $0)
        }

        let lastSyncedAt: Date? = (row["last_synced_at"] as? String).flatMap {
            ISO8601DateFormatter().date(from: $0)
        }

        return RepositoryConnection(
            id: id,
            userId: userId,
            provider: provider,
            accessToken: accessToken,
            refreshToken: refreshToken,
            scopes: scopes,
            providerUserId: providerUserId,
            providerUsername: providerUsername,
            connectedAt: connectedAt,
            expiresAt: expiresAt,
            lastSyncedAt: lastSyncedAt
        )
    }
}
