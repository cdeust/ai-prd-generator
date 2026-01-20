import Foundation
import Domain

/// Mapper for Session <-> SupabaseSessionRecord conversions
/// Single Responsibility: Maps between domain and persistence models
public struct SupabaseSessionMapper: Sendable {
    public init() {}

    private func createDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    public func toRecord(_ session: Session) -> SupabaseSessionRecord {
        let dateFormatter = createDateFormatter()
        let metadataJson = encodeMetadata(session.metadata, messages: session.messages)

        return SupabaseSessionRecord(
            id: session.id.uuidString,
            userId: session.userId.uuidString,
            prdDocumentId: session.prdDocumentId?.uuidString,
            metadataJson: metadataJson,
            startedAt: dateFormatter.string(from: session.startTime),
            endedAt: session.endTime.map { dateFormatter.string(from: $0) },
            isActive: session.metadata.isActive
        )
    }

    public func toDomain(_ record: SupabaseSessionRecord) -> Session {
        let dateFormatter = createDateFormatter()
        let (metadata, messages) = decodeMetadata(record.metadataJson)

        return Session(
            id: UUID(uuidString: record.id) ?? UUID(),
            userId: UUID(uuidString: record.userId) ?? UUID(),
            startTime: dateFormatter.date(from: record.startedAt) ?? Date(),
            messages: messages,
            metadata: metadata,
            prdDocumentId: record.prdDocumentId.flatMap { UUID(uuidString: $0) }
        )
    }

    private func encodeMetadata(_ metadata: SessionMetadata, messages: [ChatMessage]) -> String? {
        let container = SessionMetadataContainer(metadata: metadata, messages: messages)
        guard let data = try? JSONEncoder().encode(container) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decodeMetadata(_ json: String?) -> (SessionMetadata, [ChatMessage]) {
        guard let json = json,
              let data = json.data(using: .utf8),
              let container = try? JSONDecoder().decode(SessionMetadataContainer.self, from: data) else {
            return (SessionMetadata(), [])
        }
        return (container.metadata, container.messages)
    }
}
