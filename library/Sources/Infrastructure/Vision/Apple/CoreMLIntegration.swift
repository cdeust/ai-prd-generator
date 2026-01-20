// Vision components require Apple platforms
#if os(macOS) || os(iOS)
// Apple Vision framework is only available on Apple platforms
#if canImport(Vision) && (os(macOS) || os(iOS))
import Vision
import CoreML

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Core ML model integration for custom UI component detection
@available(iOS 15.0, macOS 12.0, *)
public struct CoreMLIntegration: Sendable {
    private let modelURL: URL?

    public init(modelURL: URL? = nil) {
        self.modelURL = modelURL
    }

    /// Classify components using custom Core ML model
    public func classifyWithCustomModel(
        image: CGImage,
        regions: [CGRect]
    ) async throws -> [MLComponentClassification] {
        guard let modelURL = modelURL else {
            return []
        }

        let model = try await loadModel(from: modelURL)

        var classifications: [MLComponentClassification] = []

        for region in regions {
            if let cropped = cropImage(image, to: region) {
                let result = try await classify(
                    image: cropped,
                    using: model
                )
                classifications.append(
                    MLComponentClassification(
                        region: region,
                        componentType: result.componentType,
                        confidence: result.confidence
                    )
                )
            }
        }

        return classifications
    }

    // MARK: - Private Methods

    private func loadModel(
        from url: URL
    ) async throws -> VNCoreMLModel {
        let mlModel = try MLModel(contentsOf: url)
        return try VNCoreMLModel(for: mlModel)
    }

    private func classify(
        image: CGImage,
        using model: VNCoreMLModel
    ) async throws -> (componentType: String, confidence: Double) {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) {
                request,
                error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results
                    as? [VNClassificationObservation],
                      let topResult = observations.first else {
                    continuation.resume(
                        returning: (
                            componentType: "unknown",
                            confidence: 0.0
                        )
                    )
                    return
                }

                continuation.resume(
                    returning: (
                        componentType: topResult.identifier,
                        confidence: Double(topResult.confidence)
                    )
                )
            }

            request.imageCropAndScaleOption = .scaleFill

            let handler = VNImageRequestHandler(cgImage: image)

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func cropImage(
        _ image: CGImage,
        to rect: CGRect
    ) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        let cropRect = CGRect(
            x: rect.origin.x * width,
            y: rect.origin.y * height,
            width: rect.size.width * width,
            height: rect.size.height * height
        )

        return image.cropping(to: cropRect)
    }
}
#endif // Apple platforms only

#endif // os(macOS) || os(iOS)
