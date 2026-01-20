import Foundation
import Domain

/// Mock vision analyzer for testing purposes
@available(iOS 15.0, macOS 12.0, *)
public final class MockVisionAnalyzer: VisionAnalysisPort, Sendable {
    private let stubbedResult: MockupAnalysisResult?
    private let stubbedError: Error?
    private let delay: TimeInterval

    public init(
        result: MockupAnalysisResult? = nil,
        error: Error? = nil,
        delay: TimeInterval = 0
    ) {
        self.stubbedResult = result
        self.stubbedError = error
        self.delay = delay
    }

    public func analyzeMockup(
        imageData: Data,
        prompt: String?
    ) async throws -> MockupAnalysisResult {
        if delay > 0 {
            try await Task.sleep(
                nanoseconds: UInt64(delay * 1_000_000_000)
            )
        }

        if let error = stubbedError {
            throw error
        }

        return stubbedResult ?? createDefaultResult()
    }

    public func analyzeMultipleMockups(
        images: [MockupImage]
    ) async throws -> [MockupAnalysisResult] {
        var results: [MockupAnalysisResult] = []

        for _ in images {
            let result = try await analyzeMockup(
                imageData: Data(),
                prompt: nil
            )
            results.append(result)
        }

        return results
    }

    public func extractUserFlows(
        from screens: [MockupAnalysisResult]
    ) async throws -> [UserFlow] {
        []
    }

    public var providerName: String { "Mock Provider" }
    public var modelName: String { "Mock Model" }

    private func createDefaultResult() -> MockupAnalysisResult {
        MockupAnalysisResult(
            mockupId: UUID(),
            analyzedAt: Date(),
            components: createDefaultComponents(),
            flows: [],
            interactions: createDefaultInteractions(),
            dataRequirements: [],
            metadata: createDefaultMetadata(),
            screenName: "Mock Screen",
            screenDescription: "Mock screen for testing"
        )
    }

    private func createDefaultComponents() -> [UIComponent] {
        [
            UIComponent(
                type: .button,
                label: "Submit",
                position: ComponentPosition(x: 100, y: 100, width: 200, height: 50),
                state: .enabled,
                actions: [.tap]
            ),
            UIComponent(
                type: .textField,
                label: "Email",
                position: ComponentPosition(x: 100, y: 200, width: 200, height: 40),
                state: .enabled,
                actions: [.tap, .input]
            ),
            UIComponent(
                type: .label,
                label: "Welcome",
                position: ComponentPosition(x: 100, y: 50, width: 200, height: 30),
                state: .enabled,
                actions: []
            )
        ]
    }

    private func createDefaultInteractions() -> [Interaction] {
        let componentId = UUID()
        return [
            Interaction(
                trigger: .tap,
                sourceComponentId: componentId,
                feedback: InteractionFeedback(
                    visual: .highlight,
                    haptic: HapticFeedback.light
                )
            )
        ]
    }

    private func createDefaultMetadata() -> AnalysisMetadata {
        AnalysisMetadata(
            confidence: 1.0,
            modelName: modelName,
            durationSeconds: delay,
            imageDimensions: ImageDimensions(width: 375, height: 812),
            additionalInfo: [
                "providerName": providerName,
                "isMock": "true"
            ]
        )
    }
}
