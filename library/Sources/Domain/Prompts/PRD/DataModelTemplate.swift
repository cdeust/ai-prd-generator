import Foundation

/// Data model section prompt template
/// Domain layer - Pure prompt template
public enum DataModelTemplate {
    public static let template = """
    <task>Generate Data Model Changes</task>

    <input>%@</input>

    <instruction>
    CRITICAL: Focus ONLY on what is described in the <input> section above.
    Define ONLY the data model CHANGES or ADDITIONS needed for that exact request.

    ASSUMPTIONS:
    - User, Auth, and other basic entities already exist
    - Only specify NEW entities or MODIFICATIONS to existing ones
    - If no data model changes are needed, state "No data model changes required"

    For NEW entities only:
    **[Entity Name]** (New)
    | Field | Type | Description | Required |
    |-------|------|-------------|----------|

    For MODIFIED entities:
    **[Entity Name]** (Modified)
    | New Field | Type | Description | Required |
    |-----------|------|-------------|----------|

    For NEW relationships:
    **New Relationships:**
    - [Entity1] → [Entity2]: [relationship description]

    Only include what's changing or being added for this task.
    </instruction>
    """
}
