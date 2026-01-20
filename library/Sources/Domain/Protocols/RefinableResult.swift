import Foundation

/// Protocol for results that can be refined through TRM enhancement
///
/// Conforming types can participate in recursive refinement loops
/// with intelligent halting criteria.
public protocol RefinableResult: Sendable {
    /// The conclusion or output of the reasoning
    var conclusion: String { get }

    /// Confidence score (0.0 - 1.0)
    var confidence: Double { get }
}

/// Function type for refining a result
///
/// Takes previous result, problem, and context, produces refined result.
public typealias Refiner<T: RefinableResult> = @Sendable (
    _ previousResult: T,
    _ problem: String,
    _ context: String
) async throws -> T
