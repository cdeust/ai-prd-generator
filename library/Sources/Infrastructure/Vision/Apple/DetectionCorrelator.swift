// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Foundation
import Domain

// Apple Vision framework is only available on Apple platforms
#if canImport(Vision) && (os(macOS) || os(iOS))
import Vision

/// Correlates multiple detection sources into unified components
@available(iOS 15.0, macOS 12.0, *)
struct DetectionCorrelator: Sendable {
    func correlateDetections(
        rectangles: [VNRectangleObservation],
        text: [VNRecognizedTextObservation],
        saliency: [VNSaliencyImageObservation]
    ) -> [DetectedComponent] {
        var components: [DetectedComponent] = []

        for rectangle in rectangles {
            let component = createComponent(
                from: rectangle,
                text: text,
                saliency: saliency
            )
            components.append(component)
        }

        return components
    }

    private func createComponent(
        from rectangle: VNRectangleObservation,
        text: [VNRecognizedTextObservation],
        saliency: [VNSaliencyImageObservation]
    ) -> DetectedComponent {
        let overlappingText = findOverlappingText(
            for: rectangle.boundingBox,
            in: text
        )

        let saliencyScore = calculateSaliencyScore(
            for: rectangle.boundingBox,
            in: saliency
        )

        let componentType = inferComponentType(
            boundingBox: rectangle.boundingBox,
            text: overlappingText,
            saliency: saliencyScore
        )

        let position = convertBoundingBox(rectangle.boundingBox)
        let confidence = combineConfidences(
            rectangle: rectangle.confidence,
            saliency: saliencyScore
        )

        return DetectedComponent(
            type: componentType,
            text: overlappingText,
            position: position,
            confidence: confidence
        )
    }

    private func findOverlappingText(
        for boundingBox: CGRect,
        in textObservations: [VNRecognizedTextObservation]
    ) -> String {
        let overlapping = textObservations.filter { observation in
            observation.boundingBox.intersects(boundingBox)
        }

        let texts = overlapping.compactMap { observation in
            observation.topCandidates(1).first?.string
        }

        return texts.joined(separator: " ")
    }

    private func calculateSaliencyScore(
        for boundingBox: CGRect,
        in observations: [VNSaliencyImageObservation]
    ) -> Float {
        guard let observation = observations.first,
              let salientObjects = observation.salientObjects else {
            return 0.0
        }

        let overlapping = salientObjects.filter { object in
            object.boundingBox.intersects(boundingBox)
        }

        return overlapping.map(\.confidence).max() ?? 0.0
    }

    private func inferComponentType(
        boundingBox: CGRect,
        text: String,
        saliency: Float
    ) -> ComponentType {
        let aspectRatio = boundingBox.width / boundingBox.height

        if text.lowercased().contains("button") {
            return .button
        }

        if aspectRatio > 3.0 && boundingBox.height < 0.08 {
            return .textField
        }

        if boundingBox.width > 0.8 && boundingBox.minY < 0.15 {
            return .navigationBar
        }

        if boundingBox.width > 0.8 && boundingBox.maxY > 0.85 {
            return .tabBar
        }

        if saliency > 0.7 && aspectRatio > 1.5 {
            return .button
        }

        if text.isEmpty && boundingBox.width > 0.3 {
            return .image
        }

        if !text.isEmpty {
            return .label
        }

        return .panel
    }

    private func convertBoundingBox(_ box: CGRect) -> ComponentPosition {
        ComponentPosition(
            x: Int(box.origin.x * 1000),
            y: Int(box.origin.y * 1000),
            width: Int(box.width * 1000),
            height: Int(box.height * 1000)
        )
    }

    private func combineConfidences(
        rectangle: Float,
        saliency: Float
    ) -> Float {
        (rectangle + saliency) / 2.0
    }
}
#endif // Apple platforms only

#endif // os(macOS) || os(iOS)
