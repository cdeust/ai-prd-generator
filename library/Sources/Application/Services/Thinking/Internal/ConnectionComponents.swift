import Foundation
import Domain

/// Temporary holder for connection components during parsing
/// Used by GraphConnectionAnalyzer
struct ConnectionComponents: Sendable {
    var index: Int?
    var edgeType: ContextRelationship?
    var strength: Double?
}
