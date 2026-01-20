import Foundation

/// Test specification section prompt template
/// Domain layer - Pure prompt template
public enum TestSpecTemplate {
    public static let template = """
    <task>Generate Test Specifications</task>

    <input>%@</input>

    <instruction>
    Plan your testing approach. Think systematically about test coverage and edge cases. Generate test specifications for ONLY this specific request.

    ASSUMPTIONS:
    - Existing test suite and infrastructure is in place
    - Basic tests for auth, CRUD operations, etc. already exist
    - Focus ONLY on tests specific to this new functionality

    Structure your response as:

    ## New Tests Required

    ### Unit Tests
    - [Specific feature]: [What to verify]

    ### Integration Tests
    - [How this integrates]: [Expected behavior]

    ### Edge Cases (if any)
    - [Task-specific edge case]: [How to handle]

    If this task requires minimal testing, state that and list 2-3 key tests.
    Don't over-specify - assume standard testing practices are followed.
    </instruction>
    """
}
