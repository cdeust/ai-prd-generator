import Foundation

/// Code complexity metrics
/// Value object representing code complexity measurements
public struct CodeComplexity: Sendable {
    public let cyclomaticComplexity: Int
    public let cognitiveComplexity: Int
    public let linesOfCode: Int
    public let maxNestingDepth: Int

    public init(
        cyclomaticComplexity: Int,
        cognitiveComplexity: Int,
        linesOfCode: Int,
        maxNestingDepth: Int
    ) {
        self.cyclomaticComplexity = cyclomaticComplexity
        self.cognitiveComplexity = cognitiveComplexity
        self.linesOfCode = linesOfCode
        self.maxNestingDepth = maxNestingDepth
    }

    /// Validate complexity metrics
    /// - Throws: ValidationError if metrics are invalid or inconsistent
    public func validate() throws {
        try validateCyclomaticComplexity()
        try validateCognitiveComplexity()
        try validateLinesOfCode()
        try validateNestingDepth()
        try validateConsistency()
    }

    private func validateCyclomaticComplexity() throws {
        guard cyclomaticComplexity >= 0 else {
            throw ValidationError.outOfRange(
                field: "cyclomaticComplexity",
                min: "0",
                max: nil
            )
        }

        guard cyclomaticComplexity <= 1000 else {
            throw ValidationError.outOfRange(
                field: "cyclomaticComplexity",
                min: "0",
                max: "1000"
            )
        }
    }

    private func validateCognitiveComplexity() throws {
        guard cognitiveComplexity >= 0 else {
            throw ValidationError.outOfRange(
                field: "cognitiveComplexity",
                min: "0",
                max: nil
            )
        }

        guard cognitiveComplexity <= 500 else {
            throw ValidationError.outOfRange(
                field: "cognitiveComplexity",
                min: "0",
                max: "500"
            )
        }
    }

    private func validateLinesOfCode() throws {
        guard linesOfCode >= 0 else {
            throw ValidationError.outOfRange(
                field: "linesOfCode",
                min: "0",
                max: nil
            )
        }

        guard linesOfCode <= 10_000 else {
            throw ValidationError.outOfRange(
                field: "linesOfCode",
                min: "0",
                max: "10000"
            )
        }
    }

    private func validateNestingDepth() throws {
        guard maxNestingDepth >= 0 else {
            throw ValidationError.outOfRange(
                field: "maxNestingDepth",
                min: "0",
                max: nil
            )
        }

        guard maxNestingDepth <= 20 else {
            throw ValidationError.outOfRange(
                field: "maxNestingDepth",
                min: "0",
                max: "20"
            )
        }
    }

    private func validateConsistency() throws {
        guard linesOfCode > 0 else { return }

        let complexityRatio = Double(cyclomaticComplexity) / Double(linesOfCode)

        guard complexityRatio <= 1.0 else {
            throw ValidationError.custom(
                "Cyclomatic complexity cannot exceed lines of code"
            )
        }
    }
}
