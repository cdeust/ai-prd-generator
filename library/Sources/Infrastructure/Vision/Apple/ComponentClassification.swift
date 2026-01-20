// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Foundation

/// Classification result for a region
public struct ComponentClassification: Sendable {
    public let region: CGRect
    public let identifier: String
    public let confidence: Double
}

#endif // os(macOS) || os(iOS)
