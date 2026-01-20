import Foundation

/// Public PRD response
/// Public DTO for PRD results
public struct PRDResponse: Sendable {
    public let id: UUID
    public let title: String
    public let content: String
    public let sections: [PRDSectionResponse]
    public let metadata: PRDMetadataResponse
    public let analysis: ProfessionalAnalysisResponse?

    public init(
        id: UUID,
        title: String,
        content: String,
        sections: [PRDSectionResponse],
        metadata: PRDMetadataResponse,
        analysis: ProfessionalAnalysisResponse? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sections = sections
        self.metadata = metadata
        self.analysis = analysis
    }
}
