import AIPRDSharedUtilities
import Foundation

/// Result of web research factory creation
public struct WebResearchFactoryResult: Sendable {
    public let provider: WebResearchPort
    public let isDegraded: Bool

    public init(provider: WebResearchPort, isDegraded: Bool) {
        self.provider = provider
        self.isDegraded = isDegraded
    }
}
