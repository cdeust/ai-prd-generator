import Foundation

/// Overview section prompt template
/// Domain layer - Pure prompt template
public enum OverviewTemplate {
    public static let template = """
    <task>Generate ONLY Overview Section</task>

    <input>%@</input>

    <instruction>
    CRITICAL: Focus ONLY on what is described in the <input> section above.
    Do NOT invent or imagine requirements not explicitly mentioned in the input.
    This could be a feature, bug fix, improvement, refactoring, or any other type of change.

    Write 2-3 paragraphs for the Overview section:
    - What this specific request/change does (as described in the input)
    - The problem it solves or need it addresses (as stated in the input)
    - The value it provides (as mentioned in the input)

    CRITICAL: Output ONLY the overview content.
    Do NOT include user stories, features list, or any other sections.
    Do NOT mention "this document" or "this PRD" - just write the overview.
    Base your response ONLY on the input provided above.
    </instruction>
    """
}
