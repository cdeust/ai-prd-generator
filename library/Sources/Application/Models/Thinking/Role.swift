import Foundation

/// Role specification for meta-prompting
public struct Role: Sendable {
    public let title: String
    public let domain: String
    public let characteristics: [String]

    public init(title: String, domain: String, characteristics: [String]) {
        self.title = title
        self.domain = domain
        self.characteristics = characteristics
    }

    public static let seniorArchitect = Role(
        title: "Senior Software Architect",
        domain: "software architecture and system design",
        characteristics: ["strategic thinking", "long-term maintainability", "scalability focus"]
    )

    public static let productManager = Role(
        title: "Senior Product Manager",
        domain: "product strategy and user experience",
        characteristics: ["user-centric thinking", "business value focus", "clear communication"]
    )

    public static let technicalLead = Role(
        title: "Technical Lead",
        domain: "technical implementation and best practices",
        characteristics: ["pragmatic solutions", "code quality focus", "team collaboration"]
    )
}
