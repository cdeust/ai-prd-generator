import Foundation

/// Priority levels for information gaps in PRD generation.
///
/// Determines the urgency of resolving a gap and influences resolution strategy selection.
/// Higher priority gaps require more accurate resolution methods (e.g., user query over assumptions).
public enum GapPriority: String, Codable, Sendable, CaseIterable {
    /// Critical gap that blocks PRD generation
    /// - Must resolve before proceeding
    /// - Requires high-confidence resolution (> 90%)
    /// - Consider user query if automatic resolution fails
    case critical

    /// High priority gap that significantly impacts PRD quality
    /// - Should resolve for production-ready PRD
    /// - Requires medium-high confidence (> 75%)
    /// - Multiple resolution strategies recommended
    case high

    /// Medium priority gap that affects completeness
    /// - Good to resolve but not blocking
    /// - Requires medium confidence (> 60%)
    /// - Single resolution strategy acceptable
    case medium

    /// Low priority gap that adds detail
    /// - Nice to have but not essential
    /// - Lower confidence acceptable (> 40%)
    /// - Informed assumptions acceptable
    case low
}

extension GapPriority {
    /// Human-readable description of the priority level.
    public var description: String {
        switch self {
        case .critical:
            return "Critical (Blocking)"
        case .high:
            return "High Priority"
        case .medium:
            return "Medium Priority"
        case .low:
            return "Low Priority"
        }
    }

    /// Minimum confidence threshold required for auto-resolution at this priority level.
    public var minimumConfidenceThreshold: Double {
        switch self {
        case .critical:
            return 0.90
        case .high:
            return 0.75
        case .medium:
            return 0.60
        case .low:
            return 0.40
        }
    }

    /// Whether to escalate to user query if automatic resolution fails.
    public var shouldEscalateToUser: Bool {
        switch self {
        case .critical, .high:
            return true
        case .medium, .low:
            return false
        }
    }

    /// Numeric value for sorting (higher = more important).
    public var numericValue: Int {
        switch self {
        case .critical:
            return 4
        case .high:
            return 3
        case .medium:
            return 2
        case .low:
            return 1
        }
    }
}

extension GapPriority: Comparable {
    public static func < (lhs: GapPriority, rhs: GapPriority) -> Bool {
        lhs.numericValue < rhs.numericValue
    }
}
