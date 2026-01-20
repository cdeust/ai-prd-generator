import Foundation
import Domain

/// Errors that can occur during prompt engineering
public enum PromptEngineeringError: Error, LocalizedError {
    case strategyNotFound(sectionType: SectionType)

    public var errorDescription: String? {
        switch self {
        case .strategyNotFound(let sectionType):
            return "No prompt strategy found for section type: \(sectionType.rawValue)"
        }
    }
}
