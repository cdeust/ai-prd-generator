import AIPRDSharedUtilities
import Foundation

/// PostgreSQL-specific errors
/// Single Responsibility: Error representation for PostgreSQL operations
public enum PostgreSQLError: Error, Sendable {
    case notConnected
    case connectionFailed(String)
    case queryFailed(String)
    case invalidResultFormat
    case parameterEncodingFailed(String)
    case transactionFailed(String)
    case invalidConnectionString
    case missingRequiredColumn(String)
    case typeConversionFailed(String)
}

extension PostgreSQLError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to PostgreSQL database"
        case .connectionFailed(let message):
            return "PostgreSQL connection failed: \(message)"
        case .queryFailed(let message):
            return "PostgreSQL query failed: \(message)"
        case .invalidResultFormat:
            return "Invalid result format from PostgreSQL"
        case .parameterEncodingFailed(let message):
            return "Failed to encode query parameter: \(message)"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .invalidConnectionString:
            return "Invalid PostgreSQL connection string"
        case .missingRequiredColumn(let column):
            return "Required column '\(column)' not found in result"
        case .typeConversionFailed(let message):
            return "Type conversion failed: \(message)"
        }
    }
}
