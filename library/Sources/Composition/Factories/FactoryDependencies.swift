import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities
import InfrastructureCore

/// Internal dependencies container for factory
/// Not exposed outside Composition layer
struct FactoryDependencies {
    let aiProvider: AIProviderPort
    let prdRepository: PRDRepositoryPort
    let templateRepository: PRDTemplateRepositoryPort
    let sessionRepository: SessionRepositoryPort
    let mockupRepository: MockupRepositoryPort
    let verificationEvidenceRepository: VerificationEvidenceRepositoryPort
}
