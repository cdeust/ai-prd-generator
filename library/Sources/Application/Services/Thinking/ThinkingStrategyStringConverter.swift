import Foundation
import Domain

/// Converts thinking strategies to string representations
/// Shared utility to avoid duplication across use cases
struct ThinkingStrategyStringConverter {
    static func toString(_ strategy: ThinkingStrategy) -> String {
        switch strategy {
        case .chainOfThought: return "chain_of_thought"
        case .treeOfThoughts: return "tree_of_thoughts"
        case .graphOfThoughts: return "graph_of_thoughts"
        case .react: return "react"
        case .reflexion: return "reflexion"
        case .planAndSolve: return "plan_and_solve"
        case .verifiedReasoning: return "verified_reasoning"
        case .recursiveRefinement: return "recursive_refinement"
        case .zeroShot: return "zero_shot"
        case .fewShot: return "few_shot"
        case .selfConsistency: return "self_consistency"
        case .generateKnowledge: return "generate_knowledge"
        case .promptChaining: return "prompt_chaining"
        case .multimodalCoT: return "multimodal_cot"
        case .metaPrompting: return "meta_prompting"
        case .enhanced(let base, let enhancement):
            return "enhanced_\(baseToString(base))_\(enhancementToString(enhancement))"
        }
    }

    static func baseToString(_ base: BaseStrategy) -> String {
        switch base {
        case .chainOfThought: return "cot"
        case .reflexion: return "reflexion"
        case .planAndSolve: return "plan_solve"
        case .verifiedReasoning: return "verified"
        }
    }

    static func enhancementToString(_ enhancement: EnhancementType) -> String {
        switch enhancement {
        case .trmRefinement: return "trm"
        }
    }
}
