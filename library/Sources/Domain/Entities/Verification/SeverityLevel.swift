import Foundation

/// Severity level for disagreement resolution
/// Following Single Responsibility: Represents severity classification
public enum SeverityLevel: String, Sendable, Codable, Comparable {
    case normal
    case warning
    case high
    case critical

    public static func < (lhs: SeverityLevel, rhs: SeverityLevel) -> Bool {
        let order: [SeverityLevel] = [.normal, .warning, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
