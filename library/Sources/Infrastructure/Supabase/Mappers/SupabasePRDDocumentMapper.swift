import Foundation
import Domain

/// Mapper between PRDDocument (Domain) and SupabasePRDDocumentRecord (Infrastructure)
/// Single Responsibility: Data transformation between layers
struct SupabasePRDDocumentMapper {
    /// Map record to domain using sections from prd_sections table
    /// Note: thoughtChain and professionalAnalysis are stored in verification evidence tables
    /// for meta-learning, not in prd_documents table
    func toDomain(_ record: SupabasePRDDocumentRecord, sections: [PRDSection]) -> PRDDocument {
        let metadata = DocumentMetadata(
            author: record.metadataJson?.author ?? "Unknown",
            projectName: record.metadataJson?.projectName ?? record.title,
            aiProvider: record.metadataJson?.aiProvider ?? "Unknown",
            generationApproach: record.metadataJson?.generationApproach,
            codebaseId: record.codebaseId.flatMap { UUID(uuidString: $0) }
        )

        return PRDDocument(
            id: UUID(uuidString: record.id) ?? UUID(),
            userId: record.userId.flatMap { UUID(uuidString: $0) } ?? UUID(),
            title: record.title,
            description: record.description,
            version: record.version ?? "1.0.0",
            status: record.status.flatMap { PRDStatus(rawValue: $0) } ?? .draft,
            privacyLevel: record.privacyLevel.flatMap { PRDPrivacyLevel(rawValue: $0) } ?? .private,
            sections: sections,
            metadata: metadata,
            professionalAnalysis: nil, // Stored in verification evidence for meta-learning
            thoughtChain: nil, // Stored in verification evidence for meta-learning
            createdAt: record.createdAt ?? Date(),
            updatedAt: record.updatedAt ?? Date()
        )
    }

    /// Legacy support: Map record to domain using sections from JSON (fallback)
    func toDomain(_ record: SupabasePRDDocumentRecord) -> PRDDocument {
        let sections = mapSectionsFromJSON(record.metadataJson?.sections)
        return toDomain(record, sections: sections)
    }

    func toRecord(_ domain: PRDDocument) -> SupabasePRDDocumentRecord {
        let metadataJson = buildMetadataJSON(domain)
        let thinkingChainJson = buildThinkingChainJSON(domain.thoughtChain)
        let professionalAnalysisJson = buildProfessionalAnalysisJSON(domain.professionalAnalysis)

        return SupabasePRDDocumentRecord(
            id: domain.id.uuidString.lowercased(),
            userId: domain.userId.uuidString.lowercased(),
            codebaseId: domain.metadata.codebaseId?.uuidString.lowercased(),
            title: domain.title,
            description: domain.description,
            version: domain.version,
            status: domain.status.rawValue,
            metadataJson: metadataJson,
            thinkingChainJson: thinkingChainJson,
            professionalAnalysisJson: professionalAnalysisJson,
            thinkingMode: domain.metadata.thinkingStrategy,
            privacyLevel: domain.privacyLevel.rawValue,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }

    private func buildMetadataJSON(_ domain: PRDDocument) -> PRDMetadataJSON {
        PRDMetadataJSON(
            author: domain.metadata.author,
            projectName: domain.metadata.projectName,
            aiProvider: domain.metadata.aiProvider,
            generationApproach: domain.metadata.generationApproach,
            sections: mapSectionsToJSON(domain.sections)
        )
    }

    private func buildThinkingChainJSON(_ chain: ThoughtChain?) -> [[String: String]]? {
        chain.map { c in
            c.thoughts.map { thought in
                [
                    "type": thought.type.rawValue,
                    "content": thought.content,
                    "confidence": String(format: "%.2f", thought.confidence)
                ]
            }
        }
    }

    private func buildProfessionalAnalysisJSON(_ analysis: ProfessionalAnalysis?) -> [String: String]? {
        guard let analysis = analysis else { return nil }

        guard let jsonData = try? JSONEncoder().encode(analysis),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return ["json": jsonString]
    }

    private func mapSectionsFromJSON(_ json: [[String: String]]?) -> [PRDSection] {
        guard let json = json else { return [] }
        return json.enumerated().compactMap { index, dict in
            guard let title = dict["title"],
                  let content = dict["content"],
                  let typeString = dict["type"],
                  let type = SectionType(rawValue: typeString) else {
                return nil as PRDSection?
            }
            return PRDSection(
                type: type,
                title: title,
                content: content,
                order: index
            )
        }
    }

    private func mapSectionsToJSON(_ sections: [PRDSection]) -> [[String: String]] {
        sections.map { ["title": $0.title, "content": $0.content, "type": $0.type.rawValue] }
    }
}
