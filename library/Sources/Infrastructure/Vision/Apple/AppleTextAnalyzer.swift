// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Foundation

// Apple Vision framework is only available on Apple platforms
#if canImport(Vision) && (os(macOS) || os(iOS))
import Vision

/// Analyzes text elements using Apple Vision framework
@available(iOS 15.0, macOS 12.0, *)
struct AppleTextAnalyzer: Sendable {
    func detectText(in image: CGImage) async throws -> [TextElement] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let elements = self.extractElements(from: request.results)
                continuation.resume(returning: elements)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func extractElements(from results: [Any]?) -> [TextElement] {
        guard let observations = results as? [VNRecognizedTextObservation] else {
            return []
        }

        return observations.compactMap { observation in
            guard let text = observation.topCandidates(1).first?.string else {
                return nil
            }

            return TextElement(
                text: text,
                confidence: observation.confidence,
                boundingBox: observation.boundingBox
            )
        }
    }
}
#endif // Apple platforms only

#endif // os(macOS) || os(iOS)
