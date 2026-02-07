import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Swift Complexity Calculator
/// Calculates cyclomatic complexity and nesting depth for Swift code
/// Single Responsibility: Only complexity calculation logic
final class SwiftComplexityCalculator: Sendable {

    func calculateComplexity(for code: String) -> CodeComplexity {
        let lines = code.components(separatedBy: .newlines).filter {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty
        }
        let cyclomaticComplexity = calculateCyclomaticComplexity(code)
        let nestingDepth = calculateMaxNestingDepth(code)

        return CodeComplexity(
            cyclomaticComplexity: cyclomaticComplexity,
            cognitiveComplexity: cyclomaticComplexity,
            linesOfCode: lines.count,
            maxNestingDepth: nestingDepth
        )
    }

    private func calculateCyclomaticComplexity(_ code: String) -> Int {
        var complexity = 1

        let controlFlowKeywords = [
            "if", "else if", "for", "while",
            "switch", "case", "catch", "guard"
        ]

        for keyword in controlFlowKeywords {
            let pattern = "\\b\(keyword)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(code.startIndex..., in: code)
                complexity += regex.numberOfMatches(in: code, range: range)
            }
        }

        return complexity
    }

    private func calculateMaxNestingDepth(_ code: String) -> Int {
        var maxDepth = 0
        var currentDepth = 0

        for char in code {
            if char == "{" {
                currentDepth += 1
                maxDepth = max(maxDepth, currentDepth)
            } else if char == "}" {
                currentDepth = max(0, currentDepth - 1)
            }
        }

        return maxDepth
    }
}
