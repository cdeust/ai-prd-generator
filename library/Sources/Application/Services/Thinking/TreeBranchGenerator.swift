import Foundation
import Domain

/// Generates branches for tree-of-thoughts exploration
/// Single Responsibility: Create diverse reasoning branches from current node
public struct TreeBranchGenerator: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Generate multiple branches from current node
    public func generate(
        node: DecisionNode,
        context: String,
        branchingFactor: Int
    ) async throws -> [DecisionNode] {
        let prompt = buildBranchingPrompt(
            question: node.question,
            currentPath: node.path,
            context: context,
            numBranches: branchingFactor
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            
            temperature: 0.8
        )

        return parseBranches(response: response, parentNode: node)
    }

    // MARK: - Private Methods

    private func buildBranchingPrompt(
        question: String,
        currentPath: [String],
        context: String,
        numBranches: Int
    ) -> String {
        let pathContext = currentPath.isEmpty ? "" : """

        <reasoning_path>
        \(currentPath.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        </reasoning_path>
        """

        return """
        Generate \(numBranches) distinct approaches to solve this problem:

        <problem>
        \(question)
        </problem>
        \(pathContext)
        <context>
        \(context)
        </context>

        For each approach, provide:
        1. A clear next step or sub-question
        2. Brief reasoning why this direction is promising
        3. Potential risks or limitations

        Format each as:
        APPROACH_N:
        STEP: [specific next step]
        REASONING: [why this is promising]
        RISKS: [potential issues]
        """
    }

    private func parseBranches(
        response: String,
        parentNode: DecisionNode
    ) -> [DecisionNode] {
        let lines = response.components(separatedBy: "\n")
        var branches: [DecisionNode] = []
        var currentStep = ""
        var currentReasoning = ""

        for line in lines {
            if line.starts(with: "STEP:") {
                currentStep = extractValue(from: line, prefix: "STEP:")
            } else if line.starts(with: "REASONING:") {
                currentReasoning = extractValue(from: line, prefix: "REASONING:")
            } else if line.starts(with: "APPROACH_") && !currentStep.isEmpty {
                branches.append(createChildNode(
                    step: currentStep,
                    reasoning: currentReasoning,
                    parent: parentNode
                ))
                currentStep = ""
                currentReasoning = ""
            }
        }

        if !currentStep.isEmpty {
            branches.append(createChildNode(
                step: currentStep,
                reasoning: currentReasoning,
                parent: parentNode
            ))
        }

        return branches
    }

    private func extractValue(from line: String, prefix: String) -> String {
        line.replacingOccurrences(of: prefix, with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func createChildNode(
        step: String,
        reasoning: String,
        parent: DecisionNode
    ) -> DecisionNode {
        DecisionNode(
            id: UUID(),
            question: step,
            criteria: [],
            children: [],
            outcome: nil,
            reasoning: reasoning,
            score: 0.5,
            depth: parent.depth + 1,
            path: parent.path + [reasoning]
        )
    }
}
