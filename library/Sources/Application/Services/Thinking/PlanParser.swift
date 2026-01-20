import Foundation
import Domain

/// Parses execution plans from LLM responses
/// Single Responsibility: Transform text responses into structured plans
public struct PlanParser: Sendable {
    public init() {}

    /// Parse structured plan from LLM response
    public func parse(response: String, problem: String) -> ExecutionPlan {
        let lines = response.components(separatedBy: "\n")
        var steps: [PlanStep] = []
        var currentStep: StepComponents = StepComponents()
        var stepNumber = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.starts(with: "STEP_") {
                if currentStep.description != nil {
                    steps.append(createStep(
                        number: stepNumber,
                        components: currentStep
                    ))
                    stepNumber += 1
                }

                currentStep = StepComponents(
                    description: extractStepDescription(from: trimmed)
                )
            } else if trimmed.starts(with: "REQUIRES:") {
                currentStep.requires = extractValue(from: trimmed, prefix: "REQUIRES:")
            } else if trimmed.starts(with: "PRODUCES:") {
                currentStep.produces = extractValue(from: trimmed, prefix: "PRODUCES:")
            } else if trimmed.starts(with: "CHALLENGES:") {
                currentStep.challenges = extractValue(from: trimmed, prefix: "CHALLENGES:")
            }
        }

        if currentStep.description != nil {
            steps.append(createStep(number: stepNumber, components: currentStep))
        }

        return ExecutionPlan(
            id: UUID(),
            problem: problem,
            steps: steps,
            createdAt: Date()
        )
    }

    // MARK: - Private Methods

    private func extractStepDescription(from line: String) -> String {
        line.replacingOccurrences(of: "^STEP_[0-9]+:", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    private func extractValue(from line: String, prefix: String) -> String {
        line.replacingOccurrences(of: prefix, with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func createStep(
        number: Int,
        components: StepComponents
    ) -> PlanStep {
        PlanStep(
            id: UUID(),
            stepNumber: number,
            description: components.description ?? "Unnamed step",
            requirements: components.requires ?? "None",
            expectedOutput: components.produces ?? "Progress toward solution",
            potentialChallenges: components.challenges ?? "None identified"
        )
    }
}

