import Foundation
import AIPRDSharedUtilities

/// Append-only JSONL audit logger with daily file rotation
/// Thread-safe via actor isolation
public actor JSONFileAuditLogger: AuditLoggerPort {
    private let baseDirectory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let dateFormatter: DateFormatter

    public init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd"
        self.dateFormatter.timeZone = TimeZone(identifier: "UTC")
    }

    public func log(_ event: AuditEvent) async {
        do {
            let fileURL = logFileURL(for: event.timestamp)
            try ensureDirectoryExists()

            let jsonData = try encoder.encode(event)
            guard var jsonLine = String(data: jsonData, encoding: .utf8) else { return }
            jsonLine.append("\n")

            if FileManager.default.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                if let data = jsonLine.data(using: .utf8) {
                    try handle.write(contentsOf: data)
                }
            } else {
                try jsonLine.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            // Audit logging must never crash the application
            print("⚠️ [AuditLogger] Failed to write event: \(error)")
        }
    }

    public func queryEvents(since: Date, type: AuditEventType?) async -> [AuditEvent] {
        do {
            let files = try logFilesSince(since)
            var events: [AuditEvent] = []

            for fileURL in files {
                guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
                let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

                for line in lines {
                    guard let data = line.data(using: .utf8),
                          let event = try? decoder.decode(AuditEvent.self, from: data) else { continue }

                    if event.timestamp >= since {
                        if let filterType = type {
                            if event.type == filterType {
                                events.append(event)
                            }
                        } else {
                            events.append(event)
                        }
                    }
                }
            }

            return events.sorted { $0.timestamp < $1.timestamp }
        } catch {
            return []
        }
    }

    // MARK: - Private

    private func logFileURL(for date: Date) -> URL {
        let dateString = dateFormatter.string(from: date)
        return baseDirectory.appendingPathComponent("audit-\(dateString).jsonl")
    }

    private func ensureDirectoryExists() throws {
        if !FileManager.default.fileExists(atPath: baseDirectory.path) {
            try FileManager.default.createDirectory(
                at: baseDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    private func logFilesSince(_ date: Date) throws -> [URL] {
        guard FileManager.default.fileExists(atPath: baseDirectory.path) else { return [] }

        let contents = try FileManager.default.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: nil
        )

        let dateString = dateFormatter.string(from: date)

        return contents
            .filter { $0.lastPathComponent.hasPrefix("audit-") && $0.pathExtension == "jsonl" }
            .filter { $0.lastPathComponent >= "audit-\(dateString).jsonl" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
