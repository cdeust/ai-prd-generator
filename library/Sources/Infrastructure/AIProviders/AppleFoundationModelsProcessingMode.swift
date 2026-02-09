import AIPRDSharedUtilities
import Foundation

/// Apple Foundation Models processing mode
/// Following Single Responsibility Principle - represents inference processing mode
@available(iOS 26.0, macOS 26.0, *)
public enum AppleFoundationModelsProcessingMode: Sendable {
    case onDevice
    case privateCloudCompute
    case hybrid
}
