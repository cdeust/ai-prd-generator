// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Foundation

/// Core ML classification result
public struct MLComponentClassification: Sendable {
    public let region: CGRect
    public let componentType: String
    public let confidence: Double
}

#endif // os(macOS) || os(iOS)
