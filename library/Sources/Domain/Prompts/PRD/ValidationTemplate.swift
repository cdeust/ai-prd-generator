import Foundation

/// Validation criteria section prompt template
/// Domain layer - Pure prompt template
public enum ValidationTemplate {
    public static let template = """
    <task>Generate Validation Criteria</task>

    <input>%@</input>

    <instruction>
    Think rigorously about verification and quality assurance. Define validation criteria for THIS specific task only.

    ASSUMPTIONS:
    - Standard validation (auth, data integrity, etc.) already exists
    - Focus on success criteria specific to this request

    **Task Completion Criteria**
    - Success looks like: [What indicates this task is done]
    - How to verify: [Specific verification for this request]
    - Key metrics: [If applicable]

    Keep it minimal - 2-4 criteria maximum.
    Must be directly related to the described task.
    If it's a simple task, one clear success criteria is sufficient.
    </instruction>
    """
}
