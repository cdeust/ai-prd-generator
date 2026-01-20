import Foundation

/// Result of a resolution attempt
public enum ResolutionResult: Codable, Sendable, Equatable {
    /// Successfully resolved with answer
    case success(answer: String)

    /// Failed to resolve
    case failure(reason: String)

    /// Inconclusive result (low confidence)
    case inconclusive(partialInfo: String?)
}

extension ResolutionResult {
    /// Extract the answer if successful
    public var answer: String? {
        switch self {
        case .success(let answer):
            return answer
        case .failure, .inconclusive:
            return nil
        }
    }

    /// Human-readable description
    public var description: String {
        switch self {
        case .success(let answer):
            return "Resolved: \(answer)"
        case .failure(let reason):
            return "Failed: \(reason)"
        case .inconclusive(let info):
            return "Inconclusive" + (info.map { ": \($0)" } ?? "")
        }
    }
}
