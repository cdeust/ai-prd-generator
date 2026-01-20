import Foundation
import Domain

/// Context builders for core PRD sections (overview, goals, requirements)
extension SectionContextExtractor {
    func buildOverviewContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            context += "Key Requirements:\n"
            let topRequirements = request.requirements.prefix(5)
            for req in topRequirements {
                context += "- \(req.description)\n"
            }
        }

        if let platform = request.platform {
            context += "\nTarget Platform: \(platform.rawValue)\n"
        }

        if let audience = request.targetAudience {
            context += "\nTarget Audience: \(audience)\n"
        }

        return context
    }

    func buildGoalsContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            context += "Requirements to achieve:\n"
            for req in request.requirements {
                context += "- \(req.description) (Priority: \(req.priority.displayName))\n"
            }
        }

        if let successCriteria = request.metadata["successCriteria"] {
            context += "\nSuccess Criteria:\n\(successCriteria)\n"
        }

        return context
    }

    func buildRequirementsContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            context += "Requirements List:\n"
            for req in request.requirements {
                context += "- \(req.description) (Priority: \(req.priority.displayName))\n"
            }
        }

        if !request.constraints.isEmpty {
            context += "\nConstraints:\n"
            for constraint in request.constraints {
                context += "- \(constraint)\n"
            }
        }

        if let platform = request.platform {
            context += "\nPlatform Constraints: \(platform.rawValue)\n"
        }

        return context
    }
}
