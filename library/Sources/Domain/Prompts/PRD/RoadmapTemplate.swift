import Foundation

/// Roadmap section prompt template
/// Domain layer - Pure prompt template
public enum RoadmapTemplate {
    public static let template = """
    <task>Generate Implementation Steps</task>

    <input>%@</input>

    <instruction>
    Plan systematically and think step-by-step through the implementation timeline and dependencies. Create a focused implementation plan for ONLY this specific task.

    ASSUMPTIONS:
    - Development environment, CI/CD, and deployment pipelines already exist
    - Basic architecture and infrastructure is in place
    - This is an incremental change to an existing system

    Format as simple steps:

    **Implementation Steps:**
    TODO: [First concrete action for this task]
    TODO: [Next step specific to this feature]
    TODO: [Continue with task-specific steps]

    **Integration Points:**
    - [How this integrates with existing system]
    - [Any existing components that need updates]

    **Testing Strategy:**
    - [Specific tests for this feature]
    - [Integration tests needed]

    Keep it practical and focused on THIS task only.
    Typically 3-7 steps maximum.
    </instruction>
    """
}
