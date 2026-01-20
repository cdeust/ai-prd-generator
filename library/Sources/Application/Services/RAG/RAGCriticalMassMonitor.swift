import Foundation
import Domain

/// Monitors and prevents RAG critical mass degradation
/// Research-backed limits prevent quality collapse from excessive context
///
/// **Research Foundation:**
/// - Liu et al. (2024): "Lost in the Middle" - LLMs miss info in long contexts
/// - Levy et al. (2024): RAG quality degrades after 15-20 chunks
/// - Anthropic (2024): Optimal context = 5-10 high-quality chunks
///
/// Following Single Responsibility: Only monitors RAG chunk limits
public struct RAGCriticalMassMonitor: Sendable {

    /// Research-backed hard limits for RAG chunk counts
    public enum Limits {
        /// OPTIMAL: 5-10 chunks - best quality/recall tradeoff
        public static let optimal = 5...10

        /// WARNING: 11-15 chunks - quality starts degrading
        public static let warning = 11...15

        /// DANGER: 16-20 chunks - severe degradation risk
        public static let danger = 16...20

        /// CRITICAL: 21+ chunks - complete failure zone
        public static let critical = 21

        /// ABSOLUTE MAX: Never exceed this (hard enforcement)
        public static let absoluteMax = 25
    }

    /// Quality zone based on chunk count
    public enum QualityZone: String, Sendable {
        case optimal = "optimal"        // 5-10 chunks
        case acceptable = "acceptable"  // 11-15 chunks
        case degraded = "degraded"      // 16-20 chunks
        case critical = "critical"      // 21-25 chunks
        case failed = "failed"          // 25+ chunks

        var emoji: String {
            switch self {
            case .optimal: return "✅"
            case .acceptable: return "⚠️"
            case .degraded: return "🔴"
            case .critical: return "💀"
            case .failed: return "🚫"
            }
        }
    }

    /// Evaluation result with recommendations
    public struct Evaluation: Sendable {
        public let requestedCount: Int
        public let enforcedLimit: Int
        public let zone: QualityZone
        public let shouldProceed: Bool
        public let warnings: [String]
        public let recommendations: [String]

        public var wasLimited: Bool {
            enforcedLimit < requestedCount
        }
    }

    public init() {}

    /// Evaluate requested chunk count and enforce limits
    /// - Parameter requestedCount: Number of chunks requested by caller
    /// - Returns: Evaluation with enforced limit and warnings
    public func evaluate(requestedCount: Int) -> Evaluation {
        let zone = determineZone(requestedCount)
        let enforcedLimit = enforceLimit(requestedCount)
        let warnings = generateWarnings(requestedCount: requestedCount, zone: zone)
        let recommendations = generateRecommendations(zone: zone, requestedCount: requestedCount)

        // Log evaluation
        print("\(zone.emoji) [RAG Monitor] Requested: \(requestedCount) chunks → Zone: \(zone.rawValue)")
        if enforcedLimit < requestedCount {
            print("🔒 [RAG Monitor] ENFORCED LIMIT: Reduced to \(enforcedLimit) chunks (was \(requestedCount))")
        }

        return Evaluation(
            requestedCount: requestedCount,
            enforcedLimit: enforcedLimit,
            zone: zone,
            shouldProceed: zone != .failed,
            warnings: warnings,
            recommendations: recommendations
        )
    }

    /// Determine quality zone based on chunk count
    private func determineZone(_ count: Int) -> QualityZone {
        switch count {
        case Limits.optimal:
            return .optimal
        case Limits.warning:
            return .acceptable
        case Limits.danger:
            return .degraded
        case Limits.critical..<Limits.absoluteMax:
            return .critical
        default:
            return .failed
        }
    }

    /// Enforce hard limit (never exceed absoluteMax)
    private func enforceLimit(_ requestedCount: Int) -> Int {
        if requestedCount > Limits.absoluteMax {
            print("🚨 [RAG Monitor] CRITICAL: Request for \(requestedCount) chunks BLOCKED (max: \(Limits.absoluteMax))")
            return Limits.absoluteMax
        }
        return requestedCount
    }

    /// Generate zone-specific warnings
    private func generateWarnings(requestedCount: Int, zone: QualityZone) -> [String] {
        var warnings: [String] = []

        switch zone {
        case .optimal:
            break // No warnings in optimal zone

        case .acceptable:
            warnings.append("Approaching quality degradation threshold (\(requestedCount)/15 chunks)")
            warnings.append("Consider reducing to 5-10 chunks for optimal quality")

        case .degraded:
            warnings.append("RAG quality severely degraded (\(requestedCount) chunks)")
            warnings.append("Lost in the Middle problem active - LLM will miss information")
            warnings.append("Recommendation: Reduce to <15 chunks immediately")

        case .critical:
            warnings.append("CRITICAL: RAG at failure threshold (\(requestedCount)/\(Limits.absoluteMax) chunks)")
            warnings.append("Context window dilution - most information will be ignored")
            warnings.append("URGENT: Reduce to <10 chunks or risk complete failure")

        case .failed:
            warnings.append("FAILED: Exceeded absolute maximum (\(requestedCount) > \(Limits.absoluteMax) chunks)")
            warnings.append("RAG system will NOT function correctly")
            warnings.append("Limit has been ENFORCED to \(Limits.absoluteMax) chunks")
        }

        return warnings
    }

    /// Generate actionable recommendations
    private func generateRecommendations(zone: QualityZone, requestedCount: Int) -> [String] {
        var recommendations: [String] = []

        switch zone {
        case .optimal:
            recommendations.append("Operating in optimal zone - no changes needed")

        case .acceptable:
            recommendations.append("Use more aggressive filtering (higher similarity threshold)")
            recommendations.append("Enable diversity selection (1 chunk per file)")
            recommendations.append("Consider query decomposition instead of more chunks")

        case .degraded:
            recommendations.append("IMMEDIATE: Reduce chunk count to <15")
            recommendations.append("Enable LLM reranking to select highest quality chunks")
            recommendations.append("Use context compression (summarize less relevant chunks)")
            recommendations.append("Split query into multiple focused searches")

        case .critical, .failed:
            recommendations.append("CRITICAL: Reduce to 5-10 chunks IMMEDIATELY")
            recommendations.append("Enable all quality filters (similarity, context-awareness, reranking)")
            recommendations.append("Consider architectural change: multi-stage retrieval")
            recommendations.append("Review query - may be too broad for single RAG call")
        }

        return recommendations
    }
}
