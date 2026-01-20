import Foundation

/// Data insights extracted from mockup analysis
public struct DataInsights: Sendable, Equatable {
    /// Total data fields identified
    public let totalFields: Int

    /// Required fields count
    public let requiredFields: Int

    /// Optional fields count
    public let optionalFields: Int

    /// Data types breakdown
    public let dataTypes: [String: Int]

    /// Validation rules identified
    public let validationRules: [String]

    public init(
        totalFields: Int,
        requiredFields: Int,
        optionalFields: Int,
        dataTypes: [String: Int],
        validationRules: [String]
    ) {
        self.totalFields = totalFields
        self.requiredFields = requiredFields
        self.optionalFields = optionalFields
        self.dataTypes = dataTypes
        self.validationRules = validationRules
    }

    /// Required fields percentage
    public var requiredFieldsPercentage: Double {
        guard totalFields > 0 else { return 0.0 }
        return Double(requiredFields) / Double(totalFields) * 100.0
    }

    /// Check if data model is complex
    public var isComplex: Bool {
        totalFields > 10 || dataTypes.count > 5
    }

    /// Most common data type
    public var mostCommonDataType: String? {
        dataTypes.max(by: { $0.value < $1.value })?.key
    }
}
