import Foundation
import Domain

/// Maps vision analysis output to MockupAnalysisResult
struct AnalysisResultMapper: Sendable {
    func map(
        output: VisionAnalysisOutput,
        mockupId: UUID,
        analyzedAt: Date,
        duration: TimeInterval,
        modelName: String,
        providerName: String
    ) throws -> MockupAnalysisResult {
        let components = extractComponents(from: output)
        let componentMap = createComponentMap(components: components, output: output)
        let dataRequirements = extractDataRequirements(
            from: output,
            components: components
        )
        let interactions = extractInteractions(
            from: output,
            componentMap: componentMap
        )

        let metadata = createMetadata(
            duration: duration,
            modelName: modelName,
            providerName: providerName
        )

        let result = MockupAnalysisResult(
            mockupId: mockupId,
            analyzedAt: analyzedAt,
            components: components,
            flows: [],
            interactions: interactions,
            dataRequirements: dataRequirements,
            metadata: metadata,
            screenName: output.screenName,
            screenDescription: output.screenDescription,
            layoutType: output.layoutType,
            uncertainties: output.uncertainties ?? [],
            suggestedClarifications: output.suggestedClarifications ?? []
        )

        try result.validate()
        return result
    }

    private func extractComponents(
        from output: VisionAnalysisOutput
    ) -> [UIComponent] {
        let extractor = UIComponentExtractor()
        return output.components.map { extractor.extract(from: $0) }
    }

    private func createComponentMap(
        components: [UIComponent],
        output: VisionAnalysisOutput
    ) -> [String: UUID] {
        var map: [String: UUID] = [:]
        for (index, component) in components.enumerated() {
            map["component_\(index)"] = component.id
        }
        return map
    }

    private func extractDataRequirements(
        from output: VisionAnalysisOutput,
        components: [UIComponent]
    ) -> [InferredDataRequirement] {
        let inferrer = DataRequirementInferrer()
        let context = output.screenName ?? "Unknown Screen"

        return output.dataRequirements.enumerated().map { index, dataDTO in
            let sourceId = index < components.count ? components[index].id : UUID()
            return inferrer.infer(
                from: dataDTO,
                sourceComponentId: sourceId,
                context: context
            )
        }
    }

    private func extractInteractions(
        from output: VisionAnalysisOutput,
        componentMap: [String: UUID]
    ) -> [Interaction] {
        let extractor = InteractionExtractor()
        return output.interactions.compactMap {
            extractor.extract(from: $0, componentMap: componentMap)
        }
    }

    private func createMetadata(
        duration: TimeInterval,
        modelName: String,
        providerName: String
    ) -> AnalysisMetadata {
        let imageDimensions = ImageDimensions(width: 0, height: 0)
        var additionalInfo: [String: String] = [:]
        additionalInfo["providerName"] = providerName

        return AnalysisMetadata(
            confidence: 0.85,
            modelName: modelName,
            durationSeconds: duration,
            imageDimensions: imageDimensions,
            additionalInfo: additionalInfo
        )
    }
}

