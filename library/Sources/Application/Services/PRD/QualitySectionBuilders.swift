import Foundation
import Domain

/// Context builders for quality-focused PRD sections (user stories, acceptance, testing, deployment, risks, timeline)
extension SectionContextExtractor {
    func buildUserStoriesContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            context += "Features to support:\n"
            for req in request.requirements {
                context += "- \(req.description)\n"
            }
        }

        if let personas = request.metadata["personas"] {
            context += "\nUser Personas:\n\(personas)\n"
        }

        if let userFlows = request.metadata["userFlows"] {
            context += "\nUser Flows:\n\(userFlows)\n"
        }

        if let audience = request.targetAudience {
            context += "\nTarget Audience: \(audience)\n"
        }

        return context
    }

    func buildAcceptanceContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            context += "Requirements to validate:\n"
            for req in request.requirements {
                context += "- \(req.description)\n"
            }
        }

        if !request.constraints.isEmpty {
            context += "\nConstraints to enforce:\n"
            for constraint in request.constraints {
                context += "- \(constraint)\n"
            }
        }

        if let testScenarios = request.metadata["testScenarios"] {
            context += "\nTest Scenarios:\n\(testScenarios)\n"
        }

        return context
    }

    func buildTestingContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            context += "Features to test:\n"
            for req in request.requirements {
                context += "- \(req.description)\n"
            }
        }

        if let testScenarios = request.metadata["testScenarios"] {
            context += "\nTest scenarios:\n\(testScenarios)\n"
        }

        return context
    }

    func buildDeploymentContext(_ request: PRDRequest) -> String {
        var context = ""

        if let platform = request.platform {
            context += "Target platform: \(platform.rawValue)\n"
        }

        if !request.constraints.isEmpty {
            context += "\nDeployment constraints:\n"
            for constraint in request.constraints {
                context += "- \(constraint)\n"
            }
        }

        return context
    }

    func buildRisksContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.constraints.isEmpty {
            context += "Known constraints and limitations:\n"
            for constraint in request.constraints {
                context += "- \(constraint)\n"
            }
        }

        if !request.requirements.isEmpty {
            context += "\nHigh-priority requirements:\n"
            for req in request.requirements.filter({ $0.priority == .critical || $0.priority == .high }) {
                context += "- \(req.description)\n"
            }
        }

        return context
    }

    func buildTimelineContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            context += "Requirements to deliver:\n"
            for req in request.requirements {
                context += "- \(req.description) (Priority: \(req.priority.displayName))\n"
            }
        }

        if let timeline = request.metadata["timeline"] {
            context += "\nTimeline information:\n\(timeline)\n"
        }

        return context
    }
}
