import Foundation

/// User stories section prompt template
/// Domain layer - Pure prompt template
public enum UserStoriesTemplate {
    public static let template = """
    <task>Generate ONLY User Stories Section</task>

    <input>%@</input>

    <instruction>
    CRITICAL: Focus ONLY on what is described in the <input> section above.
    Create user stories ONLY for that exact request, not imagined functionality.

    Write 2-4 user stories as clear paragraphs (not a table).

    For each story:
    - State the user type (from the input)
    - What they want to do (based on the input)
    - Why it matters to them (inferred from the input)
    - How we verify success (based on acceptance criteria in input)

    CRITICAL: Output ONLY the user stories.
    Do NOT include overview, features, or any other sections.
    Base your response ONLY on the input provided above.
    </instruction>
    """
}
