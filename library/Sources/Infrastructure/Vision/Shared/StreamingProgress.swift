import Foundation

/// Progress updates during streaming vision analysis
public enum StreamingProgress: Sendable {
    case started
    case componentsDetected(Int)
    case flowsDetected(Int)
    case dataRequirementsDetected(Int)
    case interactionsDetected(Int)
    case parsing(percentage: Double)
    case validating
    case complete(VisionAnalysisOutput)
}

