import Foundation

/// Query filter for Supabase operations
/// Domain value object for database filtering
/// Note: Not Sendable due to Any value - used only at infrastructure boundary
public struct QueryFilter {
    public let field: String
    public let operation: FilterOperation
    public let value: Any

    public init(field: String, operation: FilterOperation, value: Any) {
        self.field = field
        self.operation = operation
        self.value = value
    }
}
