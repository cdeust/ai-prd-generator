import Foundation
import Domain

/// Builds prompts for TRM (Tiny Recursion Model) recursive refinement
///
/// Generates specialized prompts for:
/// - Latent state updates (refining internal reasoning scratchpad)
/// - Prediction refinement (improving answers using updated state)
///
/// **Usage:**
/// ```swift
/// let builder = TRMPromptBuilder()
/// let latentPrompt = builder.buildLatentUpdatePrompt(
///     problem: "What is 2+2?",
///     prediction: "4",
///     state: currentState,
///     context: ""
/// )
/// ```
public struct TRMPromptBuilder: Sendable {
    public init() {}

    // MARK: - Public Methods

    /// Build prompt for updating latent reasoning state
    ///
    /// - Parameters:
    ///   - problem: Original problem statement
    ///   - prediction: Current prediction (y)
    ///   - state: Current reasoning state (z)
    ///   - context: Additional context
    /// - Returns: Prompt for latent state update
    public func buildLatentUpdatePrompt(
        problem: String,
        prediction: String,
        state: RefinementState,
        context: String
    ) -> String {
        let formattedState = formatState(state)

        return """
        You are performing iterative reasoning refinement (TRM approach).

        ## Original Problem
        \(problem)

        \(context.isEmpty ? "" : """
        ## Context
        \(context)

        """)
        ## Current Prediction (y)
        \(prediction)

        ## Current Reasoning State (z)
        \(formattedState)

        ## Task: Update Reasoning State
        Analyze the current prediction and reasoning state. Identify:
        1. New Insights: What additional insights can you extract?
        2. Error Corrections: What mistakes exist in current prediction?
        3. Refined Hypotheses: How can you improve working hypotheses?
        4. Remaining Gaps: What uncertainties need resolution?

        Format your response exactly as follows:

        NEW_INSIGHTS:
        - [insight 1]
        - [insight 2]

        ERROR_CORRECTIONS:
        - [error 1 and fix]
        - [error 2 and fix]

        REFINED_HYPOTHESES:
        - [hypothesis 1]
        - [hypothesis 2]

        REMAINING_UNCERTAINTIES:
        - [uncertainty 1]
        - [uncertainty 2]

        EVIDENCE:
        - [evidence 1]
        - [evidence 2]
        """
    }

    /// Build prompt for refining prediction using updated state
    ///
    /// - Parameters:
    ///   - problem: Original problem statement
    ///   - state: Updated reasoning state (z)
    ///   - previousPrediction: Previous prediction (y_old)
    ///   - context: Additional context
    /// - Returns: Prompt for prediction refinement
    public func buildPredictionRefinementPrompt(
        problem: String,
        state: RefinementState,
        previousPrediction: String,
        context: String
    ) -> String {
        let formattedState = formatState(state)

        return """
        You are refining a prediction using updated reasoning state (TRM).

        ## Original Problem
        \(problem)

        \(context.isEmpty ? "" : """
        ## Context
        \(context)

        """)
        ## Previous Prediction
        \(previousPrediction)

        ## Updated Reasoning State
        \(formattedState)

        ## Task: Refine Prediction
        Generate an improved prediction that:
        1. Incorporates all new insights
        2. Corrects identified errors
        3. Applies refined hypotheses
        4. Addresses uncertainties with evidence
        5. Increases precision and confidence

        Format your response exactly as follows:

        REFINED_PREDICTION:
        [improved answer here]

        REASONING:
        [why this prediction is better]

        CONFIDENCE:
        [0.0-1.0]

        IMPROVEMENTS_MADE:
        - [improvement 1]
        - [improvement 2]
        """
    }

    /// Build initial prediction prompt
    ///
    /// - Parameters:
    ///   - problem: Problem statement
    ///   - context: Additional context
    ///   - constraints: Constraints
    /// - Returns: Prompt for initial prediction
    public func buildInitialPredictionPrompt(
        problem: String,
        context: String,
        constraints: [String]
    ) -> String {
        var prompt = """
        Please solve the following problem.

        ## Problem
        \(problem)
        """

        if !context.isEmpty {
            prompt += """


            ## Context
            \(context)
            """
        }

        if !constraints.isEmpty {
            prompt += """


            ## Constraints
            \(constraints.map { "- \($0)" }.joined(separator: "\n"))
            """
        }

        prompt += """


        Provide your answer in the following format:

        REFINED_PREDICTION:
        [your answer]

        REASONING:
        [your reasoning]

        CONFIDENCE:
        [0.0-1.0]
        """

        return prompt
    }

    /// Format refinement state for prompt inclusion
    ///
    /// - Parameter state: Refinement state
    /// - Returns: Formatted text
    public func formatState(_ state: RefinementState) -> String {
        var formatted = ""

        if !state.workingMemory.isEmpty {
            formatted += "Working Memory:\n"
            formatted += state.workingMemory.map { "- \($0)" }.joined(separator: "\n")
            formatted += "\n\n"
        }

        if !state.errorCorrections.isEmpty {
            formatted += "Error Corrections:\n"
            formatted += state.errorCorrections.map { "- \($0)" }.joined(separator: "\n")
            formatted += "\n\n"
        }

        if !state.hypotheses.isEmpty {
            formatted += "Hypotheses:\n"
            formatted += state.hypotheses.map { "- \($0)" }.joined(separator: "\n")
            formatted += "\n\n"
        }

        if !state.uncertainties.isEmpty {
            formatted += "Uncertainties:\n"
            formatted += state.uncertainties.map { "- \($0)" }.joined(separator: "\n")
            formatted += "\n\n"
        }

        if !state.evidenceGathered.isEmpty {
            formatted += "Evidence Gathered:\n"
            formatted += state.evidenceGathered.map { "- \($0)" }.joined(separator: "\n")
            formatted += "\n\n"
        }

        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
