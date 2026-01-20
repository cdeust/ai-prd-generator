import Foundation

/// Filter operation for query filtering
/// Following Single Responsibility Principle - represents database filter operations
public enum FilterOperation: String, Sendable {
    case equals = "eq"
    case notEquals = "neq"
    case greaterThan = "gt"
    case greaterThanOrEqual = "gte"
    case lessThan = "lt"
    case lessThanOrEqual = "lte"
    case like = "like"
    case ilike = "ilike"
    case `in` = "in"
    case contains = "cs"
    case containedBy = "cd"
}
