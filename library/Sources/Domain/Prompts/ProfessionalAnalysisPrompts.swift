import Foundation

/// Domain-level prompts for professional analysis (architectural conflicts, technical challenges, complexity)
/// Following conservative approach - only identify explicit issues
/// INTERNAL: Not exposed to client applications
enum ProfessionalAnalysisPrompts {

    // MARK: - System Role

    static let challengeAnalysisSystemRole = """
    You are analyzing specific product requirements to identify relevant technical challenges.

    <critical_instruction>
    You MUST be extremely conservative. Only identify issues that are EXPLICITLY present in the provided text.
    </critical_instruction>

    <role>
    Act as a strict validator that ONLY identifies challenges directly caused by explicit requirements.
    </role>

    <strict_guidelines>
    - You MUST be able to quote the exact text that causes each challenge
    - DO NOT use your general knowledge about software development
    - DO NOT predict challenges based on what's commonly seen in similar projects
    - DO NOT assume any requirements, scale, or constraints not written in the input
    - DO NOT add challenges that could apply to any software project
    - If you cannot quote specific text causing a challenge, that challenge does not exist
    - Default to returning empty results if unsure
    </strict_guidelines>

    <verification>
    For every challenge or conflict you identify, you must:
    1. Quote the exact text from the input
    2. Explain how that specific text creates the challenge
    3. If you can't do both, exclude it
    </verification>

    <approach>
    Be extremely conservative. When in doubt, return empty results rather than inventing issues.
    </approach>
    """

    // MARK: - Architectural Conflict Detection

    static let architecturalConflictTemplate = """
    <task>Detect Architectural Conflicts</task>

    <input>%@</input>

    <instruction>
    CRITICAL: Most feature requests have NO architectural conflicts. Default to returning empty results.

    Analyze the provided text ONLY for DIRECT CONTRADICTIONS between explicitly stated requirements.

    <definition>
    An architectural conflict exists ONLY when:
    - Two requirements are explicitly stated in the input
    - They DIRECTLY contradict each other (both cannot be true simultaneously)
    - You can quote the EXACT text from the input for both requirements
    </definition>

    <process>
    1. First, assume there are NO conflicts (this is usually correct)
    2. Look for explicit contradictions only (e.g., "must be real-time" vs "must work offline")
    3. If no direct contradictions exist, return {"conflicts": []}
    4. Only report a conflict if you can quote exact contradictory text
    </process>

    <outputFormat>
    If no conflicts exist, simply state: "No architectural conflicts detected."

    If real conflicts exist, describe each conflict clearly:
    - Quote the two conflicting requirements
    - Explain why they conflict
    - Describe the tradeoff decision required
    - Note the implementation impact

    Write in professional prose, not JSON.
    </outputFormat>

    <important>
    - 99%% of the time, the correct response is {"conflicts": []}
    - DO NOT invent conflicts to be helpful
    - DO NOT apply patterns from other systems
    - DO NOT generate example conflicts
    - Simple features like "snippet library" have NO conflicts
    </important>
    </instruction>
    """

    // MARK: - Technical Challenges Prediction

    static let technicalChallengesTemplate = """
    <task>Predict Technical Challenges</task>

    <input>%@</input>

    <instruction>
    CRITICAL: Most simple features have NO significant technical challenges. Default to returning empty results.

    <definition>
    A technical challenge exists ONLY when the input EXPLICITLY mentions:
    - Scale requirements (e.g., "must handle 1M users")
    - Performance constraints (e.g., "must respond in < 100ms")
    - Complex integrations (e.g., "must sync with 5 external systems")
    - Security requirements (e.g., "must be end-to-end encrypted")
    - Conflicting technical requirements
    </definition>

    <process>
    1. First, assume there are NO challenges (this is usually correct for simple features)
    2. Look ONLY for explicitly stated technical complexity
    3. If no explicit complexity is stated, return {"technical_challenges": []}
    4. Basic CRUD operations have NO technical challenges
    </process>

    <outputFormat>
    If no challenges exist, simply state: "No significant technical challenges identified."

    If real challenges exist, describe each challenge:
    - Quote the requirement that creates the challenge
    - Explain the technical challenge
    - Note when this will likely surface (planning, development, testing, production)
    - Suggest mitigation approach

    Write in clear prose, not JSON.
    </outputFormat>

    <important>
    - 90%% of the time, the correct response is {"technical_challenges": []}
    - Simple features like "snippet library", "basic CRUD", "search" have NO challenges
    - DO NOT invent challenges to appear thorough
    - DO NOT apply common patterns from other systems
    - Only report challenges explicitly created by stated requirements
    </important>
    </instruction>
    """

    // MARK: - Complexity Analysis

    static let complexityAnalysisTemplate = """
    <task>Analyze Story Complexity</task>
    <input>%@</input>
    <instruction>
    Analyze complexity using Agile story points (Fibonacci):

    COMPLEXITY INDICATORS:
    - 1-2 points: CRUD operations, simple validations
    - 3-5 points: Business logic, single integration
    - 8 points: Multi-step workflows, state management
    - 13 points: Distributed logic, unknown approach
    - 21+ points: MUST BREAK DOWN - too complex

    MULTIPLIERS:
    × Offline-first (+2x complexity)
    × Real-time sync (+2x complexity)
    × Multi-tenancy (+1.5x complexity)
    × Compliance requirements (+1.5x complexity)

    Format as JSON:
    ```json
    {
      "total_points": 13,
      "breakdown": [{
        "component": "User authentication",
        "points": 5,
        "rationale": "OAuth + email/password + session management"
      }],
      "complexity_factors": [{
        "name": "Multi-tenancy",
        "impact_multiplier": 1.5,
        "description": "Requires data isolation per tenant"
      }],
      "needs_breakdown": false,
      "suggested_splits": []
    }
    ```
    </instruction>
    """

    // MARK: - Scaling Breakpoint Analysis

    static let scalingBreakpointTemplate = """
    <task>Identify Scaling Breakpoints</task>
    <input>Architecture: %@\nFeatures: %@</input>
    <instruction>
    Identify SPECIFIC scaling breakpoints based on architecture:

    BREAKPOINT PATTERNS:
    - Single DB: ~10,000 concurrent connections
    - SQLite: ~10GB data
    - REST polling: ~1000 clients
    - Webhook processing: ~100/sec synchronous
    - Full-text search: ~1M documents without dedicated infrastructure
    - File uploads: ~100MB without chunking
    - WebSocket: ~10,000 connections per server

    Format as JSON:
    ```json
    {
      "scaling_breakpoints": [{
        "metric": "concurrent_users",
        "breakpoint": "~10,000",
        "consequence": "Database connection pool exhausted",
        "required_change": "Connection pooling or read replicas",
        "complexity_increase": 3
      }]
    }
    ```
    </instruction>
    """

    // MARK: - Dependency Chain Analysis

    static let dependencyChainTemplate = """
    <task>Map Dependency Chains</task>
    <input>%@</input>
    <instruction>
    Map feature dependencies and detect circular dependencies:

    DEPENDENCY TYPES:
    - Hard dependencies: Cannot function without
    - Soft dependencies: Degraded functionality
    - External dependencies: Third-party services
    - Hidden dependencies: Non-obvious requirements

    DETECT:
    - Circular dependency cycles
    - External service dependencies
    - Platform-specific requirements
    - Infrastructure prerequisites

    Format as JSON:
    ```json
    {
      "dependency_chains": [{
        "feature": "Real-time notifications",
        "dependencies": ["WebSocket server", "User sessions"],
        "circular_dependencies": [],
        "external_dependencies": ["FCM/APNs"],
        "hidden_dependencies": ["Message queue for reliability"]
      }]
    }
    ```
    </instruction>
    """
}
