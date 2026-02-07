import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Use case for listing PRD templates
/// Single Responsibility: Retrieve all templates or defaults only
public struct ListTemplatesUseCase: Sendable {
    private let repository: PRDTemplateRepositoryPort

    public init(repository: PRDTemplateRepositoryPort) {
        self.repository = repository
    }

    public func execute(defaultsOnly: Bool = false) async throws -> [PRDTemplate] {
        if defaultsOnly {
            return try await repository.findDefaults()
        } else {
            return try await repository.findAll()
        }
    }
}
