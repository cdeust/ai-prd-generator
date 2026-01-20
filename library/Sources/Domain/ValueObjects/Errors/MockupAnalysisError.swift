import Foundation

/// Errors specific to mockup analysis
public enum MockupAnalysisError: Error, Sendable {
    case noComponentsFound
    case invalidConfidence(Double)
    case invalidImageData
    case analysisTimeout
    case providerError(String)
}
