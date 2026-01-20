import Foundation
import Domain

/// Types of enhancements that can be applied to base strategies
public enum EnhancementType: Sendable, Hashable, Equatable {
    /// TRM-powered recursive refinement with intelligent halting
    case trmRefinement(config: TRMConfig)
}
