// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Foundation
import Domain

/// Infers interactions and data requirements from detected components
@available(iOS 15.0, macOS 12.0, *)
struct AppleInferenceEngine: Sendable {
    func enrichComponents(
        _ components: [DetectedComponent],
        withText textElements: [TextElement]
    ) -> [UIComponent] {
        components.map { component in
            let nearbyText = findNearbyText(for: component, in: textElements)

            return UIComponent(
                type: component.type,
                label: component.text.isEmpty ? nearbyText : component.text,
                position: component.position,
                state: inferState(component),
                actions: inferActions(for: component.type),
                accessibilityLabel: component.text
            )
        }
    }

    func inferInteractions(from components: [DetectedComponent]) -> [Interaction] {
        components.compactMap { component in
            guard !component.type.isDisplayOnly else { return nil }

            return Interaction(
                trigger: .tap,
                sourceComponentId: UUID(),
                feedback: InteractionFeedback(
                    visual: .highlight,
                    haptic: .light,
                    audio: nil
                )
            )
        }
    }

    func inferDataRequirements(
        from components: [DetectedComponent],
        textElements: [TextElement]
    ) -> [InferredDataRequirement] {
        components.compactMap { component in
            guard component.type.isInputField else { return nil }

            let dataType = inferDataType(from: component.text)
            let isRequired = component.text.contains("*") ||
                           component.text.lowercased().contains("required")

            return InferredDataRequirement(
                fieldName: component.text.isEmpty ? "Input Field" : component.text,
                dataType: dataType,
                isRequired: isRequired,
                sourceComponentId: UUID(),
                context: "Apple Vision Analysis"
            )
        }
    }

    func inferScreenName(from textElements: [TextElement]) -> String? {
        textElements.first { $0.boundingBox.minY > 0.9 }?.text
    }

    func inferScreenDescription(from components: [DetectedComponent]) -> String? {
        "Screen with \(components.count) UI components"
    }

    private func findNearbyText(
        for component: DetectedComponent,
        in textElements: [TextElement]
    ) -> String? {
        textElements.first { element in
            isNearby(element.boundingBox, to: component.position)
        }?.text
    }

    private func isNearby(_ box: CGRect, to position: ComponentPosition) -> Bool {
        let distance = sqrt(
            pow(Double(box.midX * 1000) - Double(position.x), 2) +
            pow(Double(box.midY * 1000) - Double(position.y), 2)
        )
        return distance < 100
    }

    private func inferState(_ component: DetectedComponent) -> ComponentState {
        component.confidence > 0.9 ? .enabled : .disabled
    }

    private func inferActions(for type: ComponentType) -> [ComponentAction] {
        switch type {
        case .button, .iconButton, .link:
            return [.tap]
        case .textField, .passwordField, .searchField:
            return [.tap, .input]
        case .toggle, .checkbox, .radioButton:
            return [.tap, .select]
        case .picker, .datePicker:
            return [.tap, .select]
        default:
            return []
        }
    }

    private func inferDataType(from text: String) -> DataType {
        let lowercased = text.lowercased()

        if lowercased.contains("email") {
            return .email
        } else if lowercased.contains("password") {
            return .password
        } else if lowercased.contains("phone") {
            return .phone
        } else if lowercased.contains("date") {
            return .date
        }

        return .text
    }
}

#endif // os(macOS) || os(iOS)
