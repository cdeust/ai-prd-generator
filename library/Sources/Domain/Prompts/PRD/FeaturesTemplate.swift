import Foundation

/// Features list section prompt template
/// Domain layer - Pure prompt template
public enum FeaturesTemplate {
    public static let template = """
    <task>Generate ONLY Features List Section</task>

    <input>%@</input>

    <instruction>
    CRITICAL: Focus ONLY on what is described in the <input> section above.
    Do NOT invent additional functionality beyond what is explicitly mentioned.
    List the specific functionality/capabilities described in the input.

    Use bullet points:
    - Feature name: Brief description
    - Another feature: What it does

    CRITICAL: Output ONLY the features list.
    Do NOT include overview, user stories, or technical details.
    </instruction>
    """
}
