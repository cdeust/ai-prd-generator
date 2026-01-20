import Foundation
import Domain

/// Service for parsing AI-generated content into PRD sections
///
/// Parses markdown-formatted PRD content and extracts structured sections.
/// Handles section identification, content extraction, and type mapping.
public struct PRDSectionParser: Sendable {
    public init() {}

    /// Parse content into structured PRD sections
    /// - Parameter content: Markdown-formatted PRD content
    /// - Returns: Array of PRDSection entities
    public func parseSections(from content: String) -> [PRDSection] {
        let lines = content.components(separatedBy: "\n")
        var sections: [PRDSection] = []
        var currentSection: (type: SectionType, title: String, content: String)?
        var order = 0

        for line in lines {
            // Recognize both ## and ### as valid section headers
            // Different AI models use different markdown hierarchies:
            // - ## for main sections (MockAI, some models)
            // - ### for subsections (Apple Foundation Models, others)
            if line.hasPrefix("### ") || line.hasPrefix("## ") {
                if let section = currentSection {
                    sections.append(createSection(from: section, order: order))
                    order += 1
                }
                currentSection = parseNewSection(from: line)
            } else if currentSection != nil {
                currentSection = appendToSection(currentSection!, line: line)
            }
        }

        // Save final section
        if let section = currentSection {
            sections.append(createSection(from: section, order: order))
        }

        return sections
    }

    private func parseNewSection(from line: String) -> (type: SectionType, title: String, content: String) {
        // Remove both ## and ### prefixes
        var title = line
        if line.hasPrefix("### ") {
            title = line.replacingOccurrences(of: "###", with: "").trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("## ") {
            title = line.replacingOccurrences(of: "##", with: "").trimmingCharacters(in: .whitespaces)
        }

        let type = mapTitleToSectionType(title)
        return (type: type, title: title, content: "")
    }

    private func appendToSection(
        _ section: (type: SectionType, title: String, content: String),
        line: String
    ) -> (type: SectionType, title: String, content: String) {
        return (
            type: section.type,
            title: section.title,
            content: section.content + line + "\n"
        )
    }

    private func createSection(
        from section: (type: SectionType, title: String, content: String),
        order: Int
    ) -> PRDSection {
        return PRDSection(
            type: section.type,
            title: section.title,
            content: section.content.trimmingCharacters(in: .whitespacesAndNewlines),
            order: order
        )
    }

    private func mapTitleToSectionType(_ title: String) -> SectionType {
        let lowercased = title.lowercased()
        if lowercased.contains("overview") { return .overview }
        if lowercased.contains("goal") { return .goals }
        if lowercased.contains("requirement") { return .requirements }
        if lowercased.contains("user stor") { return .userStories }
        if lowercased.contains("technical") { return .technicalSpecification }
        if lowercased.contains("acceptance") { return .acceptanceCriteria }
        if lowercased.contains("data model") { return .dataModel }
        if lowercased.contains("api") { return .apiSpecification }
        if lowercased.contains("security") { return .securityConsiderations }
        if lowercased.contains("performance") { return .performanceRequirements }
        if lowercased.contains("test") { return .testing }
        if lowercased.contains("deploy") { return .deployment }
        if lowercased.contains("risk") { return .risks }
        if lowercased.contains("timeline") || lowercased.contains("milestone") { return .timeline }
        return .overview
    }
}
