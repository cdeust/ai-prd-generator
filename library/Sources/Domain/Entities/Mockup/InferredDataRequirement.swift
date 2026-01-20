import Foundation

/// Data requirement inferred from form fields in mockup
public struct InferredDataRequirement: Sendable, Codable, Equatable, Identifiable {
    /// Unique identifier
    public let id: UUID

    /// Field name
    public let fieldName: String

    /// Data type
    public let dataType: DataType

    /// Is field required?
    public let isRequired: Bool

    /// Validation rules
    public let validationRules: [ValidationRule]

    /// Source component ID
    public let sourceComponentId: UUID

    /// Context (form name, screen name, etc.)
    public let context: String

    /// Placeholder text
    public let placeholder: String?

    /// Default value
    public let defaultValue: String?

    /// Help text or description
    public let helpText: String?

    public init(
        id: UUID = UUID(),
        fieldName: String,
        dataType: DataType,
        isRequired: Bool,
        validationRules: [ValidationRule] = [],
        sourceComponentId: UUID,
        context: String,
        placeholder: String? = nil,
        defaultValue: String? = nil,
        helpText: String? = nil
    ) {
        self.id = id
        self.fieldName = fieldName
        self.dataType = dataType
        self.isRequired = isRequired
        self.validationRules = validationRules
        self.sourceComponentId = sourceComponentId
        self.context = context
        self.placeholder = placeholder
        self.defaultValue = defaultValue
        self.helpText = helpText
    }

    /// Check if field has validation rules
    public var hasValidation: Bool {
        !validationRules.isEmpty
    }
}
