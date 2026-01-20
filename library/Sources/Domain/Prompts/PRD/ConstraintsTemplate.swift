import Foundation

/// Constraints section prompt template
/// Domain layer - Pure prompt template
public enum ConstraintsTemplate {
    public static let template = """
    <task>Define Task-Specific Constraints</task>

    <input>%@</input>
    <technicalStack>%@</technicalStack>

    <instruction>
    Think critically about limitations and dependencies. Identify ONLY constraints specific to this request.

    ASSUMPTIONS:
    - System-wide constraints (auth, general performance, security) already defined
    - Focus ONLY on additional constraints introduced by this specific request

    List only if applicable:
    - **Performance**: Any special requirements for this request
    - **Security**: Additional security needs beyond standard
    - **Data**: Specific data constraints for this request
    - **Integration**: Constraints from external systems

    If this task introduces no special constraints beyond standard practices,
    state: "No additional constraints. Follows existing system standards."

    Keep it brief and task-specific.
    </instruction>
    """
}
