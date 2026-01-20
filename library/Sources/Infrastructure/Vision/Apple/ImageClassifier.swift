// Vision components require Apple platforms
#if os(macOS) || os(iOS)
// Apple Vision framework is only available on Apple platforms
#if canImport(Vision) && (os(macOS) || os(iOS))
import Vision
import CoreImage

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Classifies UI components using VNClassifyImageRequest
@available(iOS 15.0, macOS 12.0, *)
struct ImageClassifier: Sendable {
    /// Classify image regions to determine component types
    func classify(
        image: CGImage,
        regions: [CGRect]
    ) async throws -> [ComponentClassification] {
        var classifications: [ComponentClassification] = []

        for region in regions {
            if let cropped = cropImage(image, to: region) {
                let classification = try await classifyRegion(cropped)
                classifications.append(
                    ComponentClassification(
                        region: region,
                        identifier: classification.identifier,
                        confidence: classification.confidence
                    )
                )
            }
        }

        return classifications
    }

    // MARK: - Private Methods

    private func classifyRegion(
        _ image: CGImage
    ) async throws -> (identifier: String, confidence: Double) {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results
                    as? [VNClassificationObservation],
                      let topResult = observations.first else {
                    continuation.resume(
                        returning: (identifier: "unknown", confidence: 0.0)
                    )
                    return
                }

                continuation.resume(
                    returning: (
                        identifier: topResult.identifier,
                        confidence: Double(topResult.confidence)
                    )
                )
            }

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
