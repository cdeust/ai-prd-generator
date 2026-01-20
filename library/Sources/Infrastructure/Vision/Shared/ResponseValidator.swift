import Foundation

/// Validates vision analysis responses for correctness
public struct ResponseValidator: Sendable {
    public init() {}

    public func validate(
        _ output: VisionAnalysisOutput
    ) throws {
        try validateComponents(output.components)
        try validateInteractions(
            output.interactions,
            components: output.components
        )
        try validateUserFlows(
            output.userFlows,
            components: output.components
        )
    }

    private func validateComponents(
        _ components: [VisionAnalysisOutput.ComponentDTO]
    ) throws {
        guard !components.isEmpty else {
            throw ValidationError.noComponents
        }

        guard components.count <= 500 else {
            throw ValidationError.tooManyComponents(components.count)
        }

        for (index, component) in components.enumerated() {
            try validateComponent(component, at: index)
        }
    }

    private func validateComponent(
        _ component: VisionAnalysisOutput.ComponentDTO,
        at index: Int
    ) throws {
        guard component.position.x >= 0, component.position.y >= 0 else {
            throw ValidationError.invalidPosition(index: index)
        }

        guard component.position.width > 0 else {
            throw ValidationError.invalidWidth(index: index)
        }

        guard component.position.height > 0 else {
            throw ValidationError.invalidHeight(index: index)
        }

        guard !component.type.isEmpty else {
            throw ValidationError.missingComponentType(index: index)
        }
    }

    private func validateInteractions(
        _ interactions: [VisionAnalysisOutput.InteractionDTO],
        components: [VisionAnalysisOutput.ComponentDTO]
    ) throws {
        let componentIds = Set(
            components.indices.map { "component_\($0)" }
        )

        for interaction in interactions {
            guard componentIds.contains(interaction.componentId) else {
                throw ValidationError.invalidComponentReference(
                    interaction.componentId
                )
            }
        }
    }

    private func validateUserFlows(
        _ flows: [VisionAnalysisOutput.UserFlowDTO],
        components: [VisionAnalysisOutput.ComponentDTO]
    ) throws {
        guard flows.count <= 50 else {
            throw ValidationError.tooManyFlows(flows.count)
        }
    }
}

