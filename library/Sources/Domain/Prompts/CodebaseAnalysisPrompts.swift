import Foundation

/// Domain-level prompts for codebase analysis (RAG context building)
/// Used for archaeological code exploration and feature mapping
/// INTERNAL: Not exposed to client applications
enum CodebaseAnalysisPrompts {

    // MARK: - Codebase Structure Analysis

    static let codebaseStructureTemplate = """
    <task>Analyze Codebase Structure</task>

    <input>Codebase Path: %@</input>

    <instruction>
    Plan your codebase exploration strategy. Explore and investigate the codebase structure at the specified path. Think about the architectural patterns and design decisions.

    Identify:
    - File and directory organization
    - Primary programming language
    - Frameworks and libraries used
    - Architectural patterns
    - Key entry points
    </instruction>
    """

    static let codingPatternsTemplate = """
    <task>Identify Coding Patterns</task>

    <input>
    Structure: %@
    Focus area: %@
    </input>

    <instruction>
    Research and discover coding patterns in the specified codebase structure. Think about consistency and best practices.

    Look for:
    - Design patterns (MVC, MVVM, etc.)
    - Code organization principles
    - Naming conventions
    - Testing strategies
    - Error handling patterns
    </instruction>
    """

    static let codeArtifactsTemplate = """
    <task>Analyze Code Artifacts</task>

    <input>
    Focus: %@
    Patterns found: %@
    </input>

    <instruction>
    Analyze significant code artifacts based on the identified patterns.

    Identify:
    - Core business logic components
    - Key data models
    - Critical algorithms
    - Integration points
    - Technical debt indicators
    </instruction>
    """

    static let historicalAnalysisTemplate = """
    <task>Analyze Historical Evolution</task>

    <input>
    Based on patterns: %@
    And artifacts: %@ items
    </input>

    <instruction>
    Think like an archaeologist - piece together clues to reconstruct the historical evolution of this codebase. Consider the layers of changes over time.

    Infer:
    - Original architecture
    - Major refactorings
    - Technology migrations
    - Team changes evident in code style
    - Technical debt accumulation
    </instruction>
    """

    // MARK: - Feature-to-Code Mapping

    static let featureToCodeMappingTemplate = """
    <task>Map Feature to Code</task>

    <input>
    Feature from PRD: "%@"
    Source files in project:
    %@
    </input>

    <instruction>
    Identify which files are most likely to contain or need implementation for this feature.
    List top 5-10 files with confidence scores.
    </instruction>
    """

    static let codeFeatureAnalysisTemplate = """
    <task>Analyze Code for Feature Implementation</task>

    <input>
    Feature: "%@"
    File: %@
    Content preview:
    %@
    </input>

    <instruction>
    Analyze this code file for implementation of the specified feature.

    Determine if this feature is:
    - Fully implemented
    - Partially implemented
    - Not implemented
    - Has related code but different from PRD

    Provide evidence and line numbers.
    </instruction>
    """

    static let extractFeaturesFromPRDTemplate = """
    <task>Extract Features from PRD</task>

    <input>%@</input>

    <instruction>
    Extract distinct features from this PRD.
    List each feature as a single line description.
    Focus on implementable features, not requirements or constraints.
    </instruction>
    """

    // MARK: - Implementation Analysis

    static let implementationHypothesisTemplate = """
    <task>Generate Implementation Hypotheses</task>

    <input>
    PRD requirement: %@
    Architecture: %@
    Key patterns: %@
    </input>

    <instruction>
    Plan your implementation approach. Think critically about where and how this feature would fit into the existing codebase. Reason through the implementation and generate hypotheses about:
    - Where this feature would be implemented
    - What existing code needs modification
    - Integration points required
    - Potential conflicts or challenges
    </instruction>
    """

    static let discrepancyAnalysisTemplate = """
    <task>Analyze Implementation Discrepancies</task>

    <input>
    PRD: %@
    Verification Results: %@
    </input>

    <instruction>
    Carefully compare the PRD requirements against the verification results. Think about what's missing or different, then identify discrepancies:
    - Missing implementations
    - Partial implementations
    - Conflicting implementations
    - Unexpected behaviors
    </instruction>
    """

    static let rootCauseAnalysisTemplate = """
    <task>Perform Root Cause Analysis</task>

    <input>Discrepancies: %@</input>

    <instruction>
    Think deeply and systematically to perform root cause analysis on the identified discrepancies. Use first principles thinking.

    For each major issue:
    - Start with the symptom
    - Ask "why" five times
    - Identify root technical cause
    - Suggest remediation
    </instruction>
    """
}
