import Foundation
import Domain

/// Service that asks LLM to recommend optimal thinking strategy for a section
public struct StrategyRecommendationService: Sendable {
    private let aiProvider: AIProviderPort
    private let intelligenceTracker: IntelligenceTrackerService?
    private let verifier: LLMResponseVerifier?

    public init(
        aiProvider: AIProviderPort,
        intelligenceTracker: IntelligenceTrackerService? = nil,
        verifier: LLMResponseVerifier? = nil
    ) {
        self.aiProvider = aiProvider
        self.intelligenceTracker = intelligenceTracker
        self.verifier = verifier
    }

    /// Ask LLM to recommend thinking strategy for a PRD section
    public func recommendStrategy(
        prdId: UUID?,
        sectionType: SectionType,
        projectTitle: String,
        projectDescription: String,
        requirementCount: Int,
        hasCodebase: Bool,
        hasMockups: Bool
    ) async throws -> ThinkingStrategy {
        let prompt = buildStrategyPrompt(
            sectionType: sectionType,
            projectTitle: projectTitle,
            projectDescription: projectDescription,
            requirementCount: requirementCount,
            hasCodebase: hasCodebase,
            hasMockups: hasMockups
        )

        let startTime = Date()
        var response = ""
        for try await chunk in try await aiProvider.streamText(prompt: prompt, temperature: 0.3) {
            response += chunk
        }
        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

        // Apply Chain of Verification to strategy recommendation
        if let verifier = verifier {
            let context = "Strategy recommendation for PRD section: \(sectionType.displayName)"
            let verificationResult = try await verifier.verifyResponse(
                prompt: prompt,
                response: response,
                context: context,
                verificationType: .prdQuality
            )

            if !verificationResult.verified {
                print("⚠️ [StrategyRecommendationService] Strategy verification failed - using response with caution")
            }
        }

        await trackRecommendation(prdId: prdId, sectionType: sectionType, prompt: prompt, response: response, latencyMs: latencyMs)
        return parseStrategyResponse(response)
    }

    private func trackRecommendation(
        prdId: UUID?,
        sectionType: SectionType,
        prompt: String,
        response: String,
        latencyMs: Int
    ) async {
        guard let tracker = intelligenceTracker else { return }
        do {
            _ = try await tracker.trackLLMInteraction(
                prdId: prdId,
                sectionId: nil,
                purpose: .strategySelection,
                contextType: nil,
                promptTemplate: "strategy_recommendation",
                actualPrompt: prompt,
                systemInstructions: nil,
                llmModel: aiProvider.modelName,
                provider: aiProvider.providerName,
                parameters: LLMParameters(temperature: 0.3),
                response: response,
                tokensPrompt: nil,
                tokensResponse: nil,
                latencyMs: latencyMs,
                thinkingStrategy: nil,
                thinkingDepth: nil
            )
            print("✅ [Intelligence] Tracked strategy recommendation for \(sectionType.displayName)")
        } catch {
            print("❌ [Intelligence] Failed to track strategy recommendation: \(error)")
        }
    }

    private func buildStrategyPrompt(
        sectionType: SectionType,
        projectTitle: String,
        projectDescription: String,
        requirementCount: Int,
        hasCodebase: Bool,
        hasMockups: Bool
    ) -> String {
        let sectionGuidance = getSectionSpecificGuidance(sectionType, hasCodebase: hasCodebase, hasMockups: hasMockups)

        return """
        You are an expert AI reasoning strategist. Select the OPTIMAL thinking strategy for generating this PRD section.

        **PROJECT CONTEXT:**
        - Title: \(projectTitle)
        - Description: \(projectDescription.prefix(200))...
        - Requirements: \(requirementCount) items
        - Has Codebase: \(hasCodebase)
        - Has Mockups: \(hasMockups)

        **SECTION TO GENERATE:** \(sectionType.displayName)

        **SECTION-SPECIFIC GUIDANCE:**
        \(sectionGuidance)

        **AVAILABLE STRATEGIES (choose based on section needs):**

        FOR SIMPLE/OVERVIEW SECTIONS:
        - zero_shot: Direct generation for well-defined, straightforward content (Overview, simple Goals)
        - few_shot: Pattern-based generation using examples

        FOR TECHNICAL SECTIONS:
        - react: Best when codebase context is available - retrieves relevant code patterns (Technical Spec)
        - verified_reasoning: Multi-step verification for accuracy-critical sections (Requirements, Technical Spec)
        - plan_and_solve: Break complex technical content into sequential sub-tasks

        FOR CREATIVE/EXPLORATORY SECTIONS:
        - tree_of_thoughts: Explore multiple approaches for creative content (User Stories, Goals)
        - graph_of_thoughts: Handle interconnected dependencies

        FOR VISUAL/MOCKUP-HEAVY SECTIONS:
        - multimodal_cot: Reasoning that incorporates visual mockup analysis

        FOR ITERATIVE REFINEMENT:
        - reflexion: Self-critique and improvement (Acceptance Criteria)
        - recursive_refinement: Maximum quality through test-time compute

        **DECISION CRITERIA:**
        1. If hasCodebase=true AND section is Technical → prefer "react" or "verified_reasoning"
        2. If hasMockups=true → consider "multimodal_cot"
        3. If section is Overview or simple → prefer "zero_shot"
        4. If section requires precision (Requirements, Acceptance Criteria) → prefer "verified_reasoning"
        5. If section is creative (User Stories) → prefer "tree_of_thoughts"

        **RESPOND WITH ONLY THE STRATEGY NAME** (e.g., "react", "verified_reasoning", "zero_shot").
        Do NOT default to chain_of_thought unless no other strategy fits.

        STRATEGY:
        """
    }

    private func getSectionSpecificGuidance(_ sectionType: SectionType, hasCodebase: Bool, hasMockups: Bool) -> String {
        switch sectionType {
        case .overview:
            return "Overview sections are typically straightforward. Use zero_shot unless project is very complex."
        case .goals:
            return "Goals may benefit from exploring multiple perspectives. Consider tree_of_thoughts for creative exploration or zero_shot for clear objectives."
        case .requirements:
            if hasCodebase {
                return "Requirements with codebase context benefit from react (to find existing patterns) or verified_reasoning (for accuracy)."
            }
            return "Requirements need precision. Use verified_reasoning for complex requirements or plan_and_solve for many requirements."
        case .userStories:
            return "User stories are creative and user-focused. tree_of_thoughts helps explore different user perspectives."
        case .technicalSpecification:
            if hasCodebase {
                return "Technical specs with codebase MUST use react to retrieve relevant code patterns and architectural context."
            }
            return "Technical specs need structured thinking. Use plan_and_solve or verified_reasoning."
        case .acceptanceCriteria:
            return "Acceptance criteria need precision and completeness. Use reflexion for self-critique or verified_reasoning for accuracy."
        default:
            return "Consider the complexity and whether codebase/mockup context would help."
        }
    }

    private func parseStrategyResponse(_ response: String) -> ThinkingStrategy {
        let cleaned = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "strategy:", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch cleaned {
        case "chain_of_thought", "cot":
            return .chainOfThought
        case "tree_of_thoughts", "tot":
            return .treeOfThoughts
        case "graph_of_thoughts", "got":
            return .graphOfThoughts
        case "react":
            return .react
        case "reflexion":
            return .reflexion
        case "plan_and_solve", "plan_solve":
            return .planAndSolve
        case "verified_reasoning", "verified":
            return .verifiedReasoning
        case "recursive_refinement", "trm":
            return .recursiveRefinement
        case "zero_shot":
            return .zeroShot
        case "few_shot":
            return .fewShot([])  // Empty examples array
        case "self_consistency":
            return .selfConsistency
        case "generate_knowledge":
            return .generateKnowledge
        case "prompt_chaining":
            return .promptChaining
        case "multimodal_cot":
            return .multimodalCoT
        case "meta_prompting":
            return .metaPrompting
        default:
            print("⚠️ Unknown strategy '\(cleaned)', defaulting to zero_shot")
            return .zeroShot
        }
    }
}
