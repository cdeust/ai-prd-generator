import Foundation
import Domain

/// Extracts Interaction entities from vision analysis DTOs
struct InteractionExtractor: Sendable {
    func extract(
        from dto: VisionAnalysisOutput.InteractionDTO,
        componentMap: [String: UUID]
    ) -> Interaction? {
        guard let sourceId = componentMap[dto.componentId] else {
            return nil
        }

        let trigger = parseTrigger(dto.trigger)
        let feedback = dto.feedback.flatMap { parseFeedback($0) }

        return Interaction(
            trigger: trigger,
            sourceComponentId: sourceId,
            targetScreenId: nil,
            feedback: feedback,
            description: dto.action
        )
    }

    private func parseTrigger(_ triggerString: String) -> InteractionTrigger {
        switch triggerString.lowercased() {
        case "tap", "click":
            return .tap
        case "doubletap", "double tap":
            return .doubleTap
        case "longpress", "long press":
            return .longPress
        case "swipe", "swipeleft", "swiperight", "swipeup", "swipedown":
            return .swipe
        case "scroll":
            return .scroll
        case "drag", "drop":
            return .drag
        case "input", "type", "enter":
            return .input
        case "submit":
            return .submit
        case "focus":
            return .focus
        case "blur":
            return .blur
        case "load":
            return .load
        case "timer":
            return .timer
        case "gesture", "pinch", "rotate":
            return .gesture
        case "keyboard":
            return .keyboard
        case "voice":
            return .voice
        default:
            return .tap
        }
    }

    private func parseFeedback(
        _ dto: VisionAnalysisOutput.FeedbackDTO
    ) -> InteractionFeedback {
        let visual = dto.visual.flatMap { parseVisualFeedback($0) }
        let haptic = dto.haptic.flatMap { parseHapticFeedback($0) }
        let audio = dto.audio.flatMap { parseAudioFeedback($0) }

        return InteractionFeedback(
            visual: visual,
            haptic: haptic,
            audio: audio
        )
    }

    private func parseVisualFeedback(_ string: String) -> VisualFeedback? {
        switch string.lowercased() {
        case "highlight":
            return .highlight
        case "animation", "scale", "ripple", "fade", "bounce", "shake", "flash":
            return .animation
        case "colorchange", "color change":
            return .colorChange
        case "transition":
            return .transition
        case "toast":
            return .toast
        case "alert":
            return .alert
        case "spinner", "loading":
            return .spinner
        default:
            return nil
        }
    }

    private func parseHapticFeedback(_ string: String) -> HapticFeedback? {
        switch string.lowercased() {
        case "light":
            return .light
        case "medium":
            return .medium
        case "heavy":
            return .heavy
        case "success":
            return .success
        case "warning":
            return .warning
        case "error":
            return .error
        case "selection":
            return .selection
        default:
            return nil
        }
    }

    private func parseAudioFeedback(_ string: String) -> AudioFeedback? {
        switch string.lowercased() {
        case "click":
            return .click
        case "beep":
            return .beep
        case "success":
            return .success
        case "error":
            return .error
        case "notification", "alert":
            return .notification
        default:
            return nil
        }
    }
}

