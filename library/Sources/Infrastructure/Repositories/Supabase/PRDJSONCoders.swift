import Foundation
import Domain

/// JSON encoding/decoding helpers for PRD complex types
/// Single Responsibility: JSON serialization of PRD entities
struct PRDJSONCoders {
    func encodeAssumptions(_ assumptions: [Assumption]) -> String? {
        guard !assumptions.isEmpty else { return nil }
        let data = try? JSONEncoder().encode(assumptions)
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }

    func decodeAssumptions(_ json: String?) -> [Assumption] {
        guard let json = json,
              let data = json.data(using: .utf8),
              let assumptions = try? JSONDecoder().decode([Assumption].self, from: data) else {
            return []
        }
        return assumptions
    }

    func encodeOpenAPISpec(_ spec: OpenAPISpecification?) -> String? {
        guard let spec = spec else { return nil }
        let data = try? JSONEncoder().encode(spec)
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }

    func decodeOpenAPISpec(_ json: String?) -> OpenAPISpecification? {
        guard let json = json,
              let data = json.data(using: .utf8),
              let spec = try? JSONDecoder().decode(OpenAPISpecification.self, from: data) else {
            return nil
        }
        return spec
    }

    func encodeTestSuite(_ suite: TestSuite?) -> String? {
        guard let suite = suite else { return nil }
        let data = try? JSONEncoder().encode(suite)
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }

    func decodeTestSuite(_ json: String?) -> TestSuite? {
        guard let json = json,
              let data = json.data(using: .utf8),
              let suite = try? JSONDecoder().decode(TestSuite.self, from: data) else {
            return nil
        }
        return suite
    }
}
