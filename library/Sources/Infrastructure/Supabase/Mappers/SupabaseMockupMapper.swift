import Foundation
import Domain

/// Mapper between Mockup (Domain) and SupabaseMockupRecord (Infrastructure)
/// Single Responsibility: Data transformation between layers
struct SupabaseMockupMapper: Sendable {
    private func createDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    func toDomain(_ record: SupabaseMockupRecord) -> Mockup {
        let dateFormatter = createDateFormatter()
        let analysisResult = decodeAnalysisResult(record.analysisResultJson)

        return Mockup(
            id: UUID(uuidString: record.id) ?? UUID(),
            prdDocumentId: record.prdDocumentId.flatMap { UUID(uuidString: $0) },
            name: record.name,
            description: record.description,
            type: MockupType(rawValue: record.mockupType) ?? .mockup,
            source: decodeSource(record.source, fileUrl: record.fileUrl),
            fileUrl: record.fileUrl,
            fileSize: record.fileSize,
            width: record.width,
            height: record.height,
            extractedElements: [],
            annotations: [],
            analysisResult: analysisResult,
            orderIndex: record.orderIndex,
            createdAt: dateFormatter.date(from: record.createdAt) ?? Date(),
            updatedAt: dateFormatter.date(from: record.updatedAt) ?? Date()
        )
    }

    func toRecord(_ mockup: Mockup) -> SupabaseMockupRecord {
        let dateFormatter = createDateFormatter()
        let analysisJson = encodeAnalysisResult(mockup.analysisResult)

        return SupabaseMockupRecord(
            id: mockup.id.uuidString.lowercased(),
            prdDocumentId: mockup.prdDocumentId?.uuidString.lowercased(),
            name: mockup.name,
            description: mockup.description,
            mockupType: mockup.type.rawValue,
            source: encodeSource(mockup.source),
            fileUrl: mockup.fileUrl,
            fileSize: mockup.fileSize,
            width: mockup.width,
            height: mockup.height,
            analysisResultJson: analysisJson,
            orderIndex: mockup.orderIndex,
            createdAt: dateFormatter.string(from: mockup.createdAt),
            updatedAt: dateFormatter.string(from: mockup.updatedAt)
        )
    }

    private func encodeSource(_ source: MockupSource) -> String {
        switch source {
        case .file:
            return "file"
        case .url:
            return "url"
        case .base64:
            return "base64"
        }
    }

    private func decodeSource(_ sourceType: String, fileUrl: String) -> MockupSource {
        switch sourceType {
        case "file":
            return .file(path: fileUrl)
        case "url":
            return .url(fileUrl)
        case "base64":
            return .base64(fileUrl)
        default:
            return .url(fileUrl)
        }
    }

    private func encodeAnalysisResult(_ result: MockupAnalysisResult?) -> String? {
        guard let result = result else { return nil }
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(result) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decodeAnalysisResult(_ json: String?) -> MockupAnalysisResult? {
        guard let json = json, let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(MockupAnalysisResult.self, from: data)
    }
}
