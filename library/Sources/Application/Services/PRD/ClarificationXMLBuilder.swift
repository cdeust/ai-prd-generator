import Foundation
import Domain

/// Builds XML-formatted clarification content for PRD sections
/// Single Responsibility: Format clarification Q&A into XML structure
struct ClarificationXMLBuilder: Sendable {

    /// Build XML element for a clarification question and answer
    func buildXML(
        question: ClarificationQuestion<String, Int, String>,
        answer: String,
        section: String
    ) -> String {
        """


        <section-clarification section="\(section)" category="\(question.category.value)">
        <question>\(question.question)</question>
        <answer>\(answer)</answer>
        <requirement>Apply this clarification when generating the \(section) section.</requirement>
        </section-clarification>
        """
    }

    /// Enrich a PRD request with clarifications by appending to description
    func enrichRequest(_ request: PRDRequest, withClarifications clarifications: String) -> PRDRequest {
        guard !clarifications.isEmpty else {
            return request
        }

        return PRDRequest(
            userId: request.userId,
            title: request.title,
            description: request.description + clarifications,
            requirements: request.requirements,
            constraints: request.constraints,
            platform: request.platform,
            metadata: request.metadata,
            codebaseId: request.codebaseId,
            templateId: request.templateId,
            mockupFileIds: request.mockupFileIds
        )
    }
}
