import Foundation

/// API specification section prompt template
/// Domain layer - Pure prompt template
public enum APISpecTemplate {
    public static let template = """
    <task>Generate API Operations for Task</task>

    <input>%@</input>

    <instruction>
    Plan your API design. Research API best practices and industry standards. List ONLY the NEW or MODIFIED API operations needed for this specific task.

    ASSUMPTIONS:
    - Standard CRUD operations for existing entities are already implemented
    - Auth, user management, and basic APIs exist
    - Focus ONLY on operations specific to this task

    Format each NEW operation as:
    **[Operation Name]** (New)
    - Business action: [What it does]
    - Triggered by: [Who/when it's used]
    - Success: [Expected outcome]
    - Failures: [What could go wrong]

    Format MODIFIED operations as:
    **[Operation Name]** (Modified)
    - Change: [What's different]
    - Reason: [Why it needs to change]

    If no new API operations are needed, state "Uses existing API operations"
    </instruction>
    """
}
