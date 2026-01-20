import Foundation

/// Output from a single chain step
public struct StepOutput: Sendable {
    public let stepIndex: Int
    public let stepName: String
    public let output: String
    public let metadata: [String: String]

    public init(stepIndex: Int, stepName: String, output: String, metadata: [String: String]) {
        self.stepIndex = stepIndex
        self.stepName = stepName
        self.output = output
        self.metadata = metadata
    }
}
