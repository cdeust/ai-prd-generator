import Foundation

/// A structured prompt template with variables and constraints
///
/// Represents a complete prompt engineering specification including:
/// - System-level instructions (role, expertise, constraints)
/// - User-facing template (with variable placeholders)
/// - Variable definitions (what to inject)
/// - Quality constraints (requirements, guidelines)
/// - Example outputs (for few-shot learning)
///
/// Variables use {variableName} syntax for interpolation.
public struct PromptTemplate: Sendable {
    /// System-level instructions that set context and role
    /// Examples: "You are a senior product manager", "You are a technical architect"
    public let systemPrompt: String

    /// User-facing prompt template with {variable} placeholders
    /// Example: "Generate an overview for {title} that addresses {description}"
    public let userPromptTemplate: String

    /// Variables to inject into the template
    /// Example: ["title": "Trading Bot", "description": "Autonomous trading system"]
    public let variables: [String: String]

    /// Quality constraints and requirements
    /// Examples: "Be specific", "Include metrics", "Length: 200-300 words"
    public let constraints: [String]

    /// Example outputs for few-shot learning
    /// Optional: Used when specific format/style is required
    public let examples: [String]

    public init(
        systemPrompt: String,
        userPromptTemplate: String,
        variables: [String: String] = [:],
        constraints: [String] = [],
        examples: [String] = []
    ) {
        self.systemPrompt = systemPrompt
        self.userPromptTemplate = userPromptTemplate
        self.variables = variables
        self.constraints = constraints
        self.examples = examples
    }

    /// Generates the final prompt by interpolating variables
    public func generate() -> String {
        var prompt = userPromptTemplate

        // Inject variables
        for (key, value) in variables {
            prompt = prompt.replacingOccurrences(of: "{\(key)}", with: value)
        }

        return prompt
    }

    /// Generates the full system + user prompt combination
    public func generateFull() -> String {
        var full = systemPrompt + "\n\n"
        full += generate()

        // Add constraints
        if !constraints.isEmpty {
            full += "\n\nConstraints:\n"
            full += constraints.map { "- \($0)" }.joined(separator: "\n")
        }

        // Add examples
        if !examples.isEmpty {
            full += "\n\nExamples:\n"
            full += examples.enumerated().map { idx, example in
                "Example \(idx + 1):\n\(example)"
            }.joined(separator: "\n\n")
        }

        return full
    }
}
