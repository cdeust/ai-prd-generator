// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Foundation

/// Represents a text element detected by Apple Vision framework
struct TextElement: Sendable {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

#endif // os(macOS) || os(iOS)
