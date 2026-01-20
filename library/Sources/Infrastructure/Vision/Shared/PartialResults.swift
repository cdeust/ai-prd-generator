import Foundation

/// Partial results extracted from streaming buffer
public struct PartialResults: Sendable {
    public let components: [VisionAnalysisOutput.ComponentDTO]
    public let flows: [VisionAnalysisOutput.UserFlowDTO]

    public init(
        components: [VisionAnalysisOutput.ComponentDTO],
        flows: [VisionAnalysisOutput.UserFlowDTO]
    ) {
        self.components = components
        self.flows = flows
    }
}

