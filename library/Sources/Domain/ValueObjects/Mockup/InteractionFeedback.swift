import Foundation

/// Feedback provided after an interaction
public struct InteractionFeedback: Sendable, Codable, Equatable {
    /// Visual feedback type
    public let visual: VisualFeedback?

    /// Haptic feedback type
    public let haptic: HapticFeedback?

    /// Audio feedback type
    public let audio: AudioFeedback?

    /// Description of the feedback
    public let description: String?

    public init(
        visual: VisualFeedback? = nil,
        haptic: HapticFeedback? = nil,
        audio: AudioFeedback? = nil,
        description: String? = nil
    ) {
        self.visual = visual
        self.haptic = haptic
        self.audio = audio
        self.description = description
    }
}
