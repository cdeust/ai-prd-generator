import Foundation

/// Analysis prompt templates for requirements and mockups
/// Domain layer - Pure prompt templates
public enum AnalysisTemplates {
    public static let requirementsAnalysis = """
    <task>Analyze Requirements Completeness</task>

    <input>%@</input>

    <instruction>
    Analyze the provided requirements to identify what information is missing or unclear.
    Focus on CRITICAL decisions that cannot be inferred and would significantly impact the architecture.

    Evaluate:
    1. What architectural decisions cannot be determined from the input
    2. What critical technical constraints are not specified
    3. What assumptions you're forced to make that could be wrong
    4. Your confidence level in generating an accurate PRD

    Generate clarification questions ONLY for:
    - Architectural decisions that have multiple valid approaches
    - Technical constraints that would change the implementation
    - Critical features that are ambiguous or contradictory
    - Scale/performance requirements that affect design

    DO NOT ask about:
    - Standard best practices (these can be assumed)
    - Implementation details that don't affect architecture
    - Technologies when reasonable defaults exist

    Format your response as JSON:
    ```json
    {
      "confidence": [0-100],
      "clarifications_needed": [
        "[Specific question about an architectural decision or critical constraint]"
      ],
      "assumptions": [
        "[Critical assumption you're making that could be wrong]"
      ],
      "gaps": [
        "[Missing information that affects the architecture]"
      ]
    }
    ```
    </instruction>
    """

    public static let mockupAnalysis = """
    <task>Analyze Mockups for Requirements</task>

    <instruction>
    Plan your mockup analysis systematically. Extract and describe:
    - Key features visible in the UI
    - User workflows and interactions
    - Data fields and forms present
    - Navigation structure
    - Business logic implied by the interface
    - User roles if apparent
    - Any integration points suggested

    Provide a comprehensive description that can be used to generate a PRD.
    </instruction>
    """
}
