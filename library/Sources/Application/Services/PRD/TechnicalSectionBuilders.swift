import Foundation
import Domain

/// Context builders for technical PRD sections (technical spec, API, data model, security, performance)
extension SectionContextExtractor {
    func buildTechnicalContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            let technicalReqs = request.requirements.filter { req in
                let desc = req.description.lowercased()
                return desc.contains("api") ||
                    desc.contains("database") ||
                    desc.contains("architecture") ||
                    desc.contains("performance") ||
                    desc.contains("security") ||
                    desc.contains("scalability")
            }

            if !technicalReqs.isEmpty {
                context += "Technical Requirements:\n"
                for req in technicalReqs {
                    context += "- \(req.description)\n"
                }
            }
        }

        if let platform = request.platform {
            context += "\nPlatform: \(platform.rawValue)\n"
        }

        if let techStack = request.metadata["techStack"] {
            context += "\nTechnology Stack:\n\(techStack)\n"
        }

        if let architecture = request.metadata["architecture"] {
            context += "\nArchitecture:\n\(architecture)\n"
        }

        return context
    }

    func buildDataModelContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            context += "Features requiring data modeling:\n"
            for req in request.requirements {
                context += "- \(req.description)\n"
            }
        }

        if let platform = request.platform {
            context += "\nPlatform: \(platform.rawValue)\n"
        }

        return context
    }

    func buildAPIContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            let apiReqs = request.requirements.filter { req in
                req.description.lowercased().contains("api") ||
                req.description.lowercased().contains("endpoint") ||
                req.description.lowercased().contains("integration")
            }

            if !apiReqs.isEmpty {
                context += "API-related requirements:\n"
                for req in apiReqs {
                    context += "- \(req.description)\n"
                }
            }
        }

        return context
    }

    func buildSecurityContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            let securityReqs = request.requirements.filter { req in
                req.description.lowercased().contains("security") ||
                req.description.lowercased().contains("auth") ||
                req.description.lowercased().contains("encrypt")
            }

            if !securityReqs.isEmpty {
                context += "Security requirements:\n"
                for req in securityReqs {
                    context += "- \(req.description)\n"
                }
            }
        }

        if !request.constraints.isEmpty {
            context += "\nSecurity constraints:\n"
            for constraint in request.constraints {
                context += "- \(constraint)\n"
            }
        }

        return context
    }

    func buildPerformanceContext(_ request: PRDRequest) -> String {
        var context = ""

        if !request.requirements.isEmpty {
            let perfReqs = request.requirements.filter { req in
                req.description.lowercased().contains("performance") ||
                req.description.lowercased().contains("latency") ||
                req.description.lowercased().contains("throughput")
            }

            if !perfReqs.isEmpty {
                context += "Performance requirements:\n"
                for req in perfReqs {
                    context += "- \(req.description)\n"
                }
            }
        }

        return context
    }
}
