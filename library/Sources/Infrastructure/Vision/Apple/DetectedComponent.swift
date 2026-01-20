// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Foundation
import Domain

/// Represents a UI component detected by Apple Vision framework
struct DetectedComponent: Sendable {
    let type: ComponentType
    let text: String
    let position: ComponentPosition
    let confidence: Float
}

#endif // os(macOS) || os(iOS)
