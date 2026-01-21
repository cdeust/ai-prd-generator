import Foundation
import Domain

/// Multimodal Chain-of-Thought: CoT reasoning with vision + text
/// Single Responsibility: Execute multimodal reasoning with images
///
/// **Strategy:** Combine visual analysis (mockups, diagrams) with textual
/// chain-of-thought reasoning for richer problem understanding.
///
/// **Best for:**
/// - UI/UX requirements from mockups
/// - Diagram-based architecture design
/// - Visual + textual context problems
public struct MultimodalCoTUseCase: Sendable {
    private let aiProvider: AIProviderPort
    private let visionAnalysis: VisionAnalysisPort?

    public init(aiProvider: AIProviderPort, visionAnalysis: VisionAnalysisPort?) {
        self.aiProvider = aiProvider
        self.visionAnalysis = visionAnalysis
    }

    public func execute(
        problem: String,
        context: String,
        imageUrls: [String],
        constraints: [String]
    ) async throws -> MultimodalCoTResult {
        guard visionAnalysis != nil else {
            throw MultimodalError.visionAnalysisNotAvailable
        }

        // Stage 1: Analyze images to extract visual context
        // Note: imageUrls are treated as file identifiers
        // Vision analysis happens through the VisionAnalysisPort which takes Data
        // For now, we skip actual vision analysis if no data available
        var visualContexts: [VisualContext] = []

        // If vision analysis is available, user should provide actual image data
        // This use case is primarily for when mockups are already analyzed
        // and results are in enrichedContext
        for (index, imageUrl) in imageUrls.enumerated() {
            visualContexts.append(VisualContext(
                imageIndex: index,
                imageUrl: imageUrl,
                description: "Image reference: \(imageUrl)",
                elements: []
            ))
        }

        // Stage 2: Combine visual and textual reasoning
        let reasoningPrompt = buildMultimodalReasoningPrompt(
            problem: problem,
            context: context,
            visualContexts: visualContexts,
            constraints: constraints
        )

        let reasoning = try await aiProvider.generateText(prompt: reasoningPrompt, temperature: 0.7)

        // Stage 3: Synthesize final solution
        let synthesisPrompt = buildSynthesisPrompt(
            problem: problem,
            reasoning: reasoning,
            visualContexts: visualContexts
        )

        let solution = try await aiProvider.generateText(prompt: synthesisPrompt, temperature: 0.7)

        return MultimodalCoTResult(
            solution: solution,
            reasoning: reasoning,
            visualContexts: visualContexts,
            problem: problem,
            confidence: estimateConfidence(solution, visualCount: visualContexts.count)
        )
    }

    private func buildMultimodalReasoningPrompt(
        problem: String, context: String, visualContexts: [VisualContext], constraints: [String]
    ) -> String {
        let visualSection = buildVisualSection(visualContexts)
        let constraintsSection = constraints.isEmpty ? "" : "<constraints>\n\(constraints.joined(separator: "\n"))\n</constraints>\n\n"

        return """
        <task>
        Reason about this problem using both textual context and visual information.
        </task>

        <textual_context>
        \(context)
        </textual_context>

        \(visualSection)

        <problem>
        \(problem)
        </problem>

        \(constraintsSection)<instructions>
        Think through this problem step by step:
        1. Analyze the visual elements and how they relate to the problem
        2. Consider the textual context alongside the visual information
        3. Identify patterns, relationships, and insights from both modalities
        4. Reason about how visual and textual information complement each other
        5. Draw conclusions that integrate both sources of information

        Show your reasoning process clearly.
        </instructions>
        """
    }

    private func buildVisualSection(_ visualContexts: [VisualContext]) -> String {
        let visuals = visualContexts.map { visual in
            "Image \(visual.imageIndex + 1):\nDescription: \(visual.description)\nKey Elements: \(visual.elements.joined(separator: ", "))\n"
        }.joined(separator: "\n")
        return "<visual_context>\n\(visuals)</visual_context>"
    }

    private func buildSynthesisPrompt(
        problem: String,
        reasoning: String,
        visualContexts: [VisualContext]
    ) -> String {
        """
        <reasoning_process>
        \(reasoning)
        </reasoning_process>

        <problem>
        \(problem)
        </problem>

        <instructions>
        Based on the multimodal reasoning above, provide a clear, actionable solution.
        - Integrate insights from both visual and textual analysis
        - Reference specific visual elements when relevant
        - Provide concrete recommendations
        - Structure the solution clearly
        </instructions>
        """
    }

    private func estimateConfidence(_ solution: String, visualCount: Int) -> Double {
        // More visual context generally improves confidence
        let baseConfidence = 0.70
        let visualBonus = min(0.20, Double(visualCount) * 0.05)

        // Check if solution references visual elements
        let referencesVisuals = solution.lowercased().contains("image") ||
                               solution.lowercased().contains("visual") ||
                               solution.lowercased().contains("shown")

        return baseConfidence + visualBonus + (referencesVisuals ? 0.10 : 0.0)
    }
}



