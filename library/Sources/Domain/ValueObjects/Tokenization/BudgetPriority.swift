import Foundation

/// Phase priority for budget allocation
public enum BudgetPriority: String, Sendable, Codable, Comparable {
    case critical
    case high
    case medium
    case low

    public static func < (lhs: BudgetPriority, rhs: BudgetPriority) -> Bool {
        let order: [BudgetPriority] = [.low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
