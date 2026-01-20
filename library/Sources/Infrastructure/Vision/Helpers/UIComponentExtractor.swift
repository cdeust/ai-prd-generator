import Foundation
import Domain

/// Extracts UIComponent entities from vision analysis DTOs
struct UIComponentExtractor: Sendable {
    func extract(
        from dto: VisionAnalysisOutput.ComponentDTO
    ) -> UIComponent {
        let componentType = parseComponentType(dto.type)
        let position = parsePosition(dto.position)
        let state = dto.state.flatMap { parseComponentState($0) }
        let actions = dto.isInteractive ? [ComponentAction.tap] : []

        var properties: [String: String] = [:]
        if let placeholder = dto.placeholder {
            properties["placeholder"] = placeholder
        }

        return UIComponent(
            type: componentType,
            label: dto.label,
            position: position,
            state: state,
            actions: actions,
            properties: properties,
            accessibilityLabel: dto.accessibilityLabel
        )
    }

    private func parseComponentType(_ typeString: String) -> ComponentType {
        let parser = ComponentTypeParser()
        return parser.parse(typeString)
    }

    private func parsePosition(
        _ dto: VisionAnalysisOutput.PositionDTO
    ) -> ComponentPosition {
        ComponentPosition(
            x: Int(dto.x),
            y: Int(dto.y),
            width: Int(dto.width),
            height: Int(dto.height)
        )
    }

    private func parseComponentState(_ stateString: String) -> ComponentState? {
        switch stateString.lowercased() {
        case "enabled":
            return .enabled
        case "disabled":
            return .disabled
        case "selected":
            return .selected
        case "focused":
            return .focused
        case "hovered":
            return .hovered
        case "pressed":
            return .pressed
        case "loading":
            return .loading
        case "error":
            return .error
        case "success":
            return .success
        case "warning":
            return .warning
        default:
            return nil
        }
    }
}

