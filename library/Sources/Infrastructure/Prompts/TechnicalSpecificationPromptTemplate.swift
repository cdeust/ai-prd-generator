import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Professional prompt template for generating Technical Specification sections
///
/// Generates comprehensive technical architecture including:
/// - System architecture (components, data flow)
/// - Technology stack (with rationale)
/// - API design (endpoints, formats)
/// - Data model (entities, relationships)
/// - Deployment strategy (infrastructure, CI/CD)
/// - Security considerations
public struct TechnicalSpecificationPromptTemplate: SectionPromptStrategy {
    public var sectionType: SectionType { .technicalSpecification }

    public init() {}

    public func generatePrompt(for context: PromptContext) -> PromptTemplate {
        let systemPrompt = """
        You are a senior technical architect with expertise in system design and software architecture.
        You create detailed technical specifications that are practical, scalable, and maintainable.
        Your designs follow industry best practices and justify technology choices with clear rationale.
        """

        let userPromptTemplate = """
        Design a practical technical architecture for this project:

        **Project:** {title}
        **Context:** {description}
        **Requirements:** {requirements}

        Create a technical specification covering:

        **1. SYSTEM ARCHITECTURE**
        Describe the high-level system components and how they interact. What are the major pieces (frontend, backend, database, external services)? How does data flow through the system? Keep this grounded in the project's actual complexity - a simple tool doesn't need microservices architecture.

        **2. TECHNOLOGY STACK**
        List specific technologies and WHY you chose them:
        - Frontend: [Technology] - Rationale: [Why this fits the project]
        - Backend: [Technology] - Rationale: [Why this fits]
        - Database: [Technology] - Rationale: [Data model fit, scalability needs]
        - Infrastructure: [Platform/approach] - Rationale: [Deployment needs]
        - Third-Party Services: [Services] - Rationale: [What they provide]

        Match technology choices to project scope. Don't recommend Kubernetes for a weekend prototype.

        **3. API DESIGN** (if applicable)
        List 5-10 key API endpoints with HTTP methods:
        - POST /api/v1/resource - Create resource
        - GET /api/v1/resource/:id - Get specific resource
        [etc.]

        Describe authentication approach (JWT, OAuth, API keys) and request/response formats.

        **4. DATA MODEL**
        List 4-8 core entities with key fields:
        ```
        User
        - id: UUID
        - email: string
        - created_at: datetime

        [Other entities]
        - [fields with types]
        ```

        Show important relationships (one-to-many, many-to-many). Describe storage strategy (relational, document, caching).

        **5. DEPLOYMENT & OPERATIONS**
        - Infrastructure: Cloud provider, container approach, scaling strategy
        - CI/CD: Build, test, and deployment pipeline
        - Monitoring: How you'll track system health and errors
        - Logging: Where logs go and how to debug issues

        **6. SECURITY**
        - Authentication/Authorization: How users are authenticated and what they can access
        - Data Protection: Encryption at rest and in transit
        - API Security: Rate limiting, input validation, protection against common attacks

        **Guidelines:**
        - Use SPECIFIC technology names and versions, not categories
        - JUSTIFY each major choice - why this technology for this project?
        - Match complexity to project scope - MVP vs enterprise system
        - Be concrete: show actual endpoint names, entity schemas
        - Derive design from requirements - what does the project actually need?
        - If it's a simple/internal tool, don't over-engineer
        """

        let constraints = [
            "Cover all 6 aspects: Architecture, Stack, API, Data, Deployment, Security",
            "Justify every major technology choice with specific rationale",
            "Use concrete specifics: actual endpoint names, entity schemas, technology versions",
            "Match technical complexity to project scope",
            "Derive design from requirements - don't over-engineer simple projects",
            "Reference specific technologies, not generic categories"
        ]

        let requirementsText = context.requirements.isEmpty
            ? "None specified - design appropriate architecture for the project"
            : context.requirements.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")

        return PromptTemplate(
            systemPrompt: systemPrompt,
            userPromptTemplate: userPromptTemplate,
            variables: [
                "title": context.title,
                "description": context.description,
                "requirements": requirementsText
            ],
            constraints: constraints
        )
    }
}
