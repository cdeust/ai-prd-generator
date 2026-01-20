import Foundation

/// Quality trend detected from historical data
public enum QualityTrend: Sendable {
    case improving(scoreDelta: Double, confidenceDelta: Double)
    case stable
    case degrading(scoreDelta: Double, confidenceDelta: Double)
    case insufficient_data

    public var description: String {
        switch self {
        case .improving(let score, let conf):
            return "Improving: score +\(String(format: "%.2f", score)), confidence +\(String(format: "%.2f", conf))"
        case .stable:
            return "Stable: no significant changes"
        case .degrading(let score, let conf):
            return "Degrading: score \(String(format: "%.2f", score)), confidence \(String(format: "%.2f", conf))"
        case .insufficient_data:
            return "Insufficient data for trend analysis"
        }
    }
}
