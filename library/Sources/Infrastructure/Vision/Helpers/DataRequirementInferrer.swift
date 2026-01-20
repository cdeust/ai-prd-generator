import Foundation
import Domain

/// Infers data requirements from vision analysis DTOs
struct DataRequirementInferrer: Sendable {
    func infer(
        from dto: VisionAnalysisOutput.DataRequirementDTO,
        sourceComponentId: UUID,
        context: String
    ) -> InferredDataRequirement {
        let dataType = parseDataType(dto.dataType)
        let validationRules = parseValidationRules(dto.validation)

        return InferredDataRequirement(
            fieldName: dto.fieldName,
            dataType: dataType,
            isRequired: dto.isRequired,
            validationRules: validationRules,
            sourceComponentId: sourceComponentId,
            context: context,
            placeholder: dto.placeholder,
            helpText: dto.helpText
        )
    }

    private func parseDataType(_ typeString: String) -> DataType {
        let parser = DataTypeParser()
        return parser.parse(typeString)
    }

    private func parseValidationRules(
        _ ruleStrings: [String]
    ) -> [ValidationRule] {
        ruleStrings.compactMap { parseValidationRule($0) }
    }

    private func parseValidationRule(_ ruleString: String) -> ValidationRule? {
        let parts = ruleString.split(separator: ":")
        guard let typeString = parts.first else { return nil }

        let parameter = parts.count > 1 ? String(parts[1]) : nil

        switch typeString.lowercased() {
        case "required":
            return ValidationRule(
                type: .required,
                parameter: nil,
                errorMessage: "This field is required"
            )
        case "minlength":
            return ValidationRule(
                type: .minLength,
                parameter: parameter,
                errorMessage: "Minimum length is \(parameter ?? "0")"
            )
        case "maxlength":
            return ValidationRule(
                type: .maxLength,
                parameter: parameter,
                errorMessage: "Maximum length is \(parameter ?? "0")"
            )
        case "pattern", "regex":
            return ValidationRule(
                type: .pattern,
                parameter: parameter,
                errorMessage: "Invalid format"
            )
        case "email":
            return ValidationRule(
                type: .email,
                parameter: nil,
                errorMessage: "Invalid email address"
            )
        case "url":
            return ValidationRule(
                type: .url,
                parameter: nil,
                errorMessage: "Invalid URL"
            )
        case "phone":
            return ValidationRule(
                type: .phone,
                parameter: nil,
                errorMessage: "Invalid phone number"
            )
        case "min", "minvalue":
            return ValidationRule(
                type: .minValue,
                parameter: parameter,
                errorMessage: "Minimum value is \(parameter ?? "0")"
            )
        case "max", "maxvalue":
            return ValidationRule(
                type: .maxValue,
                parameter: parameter,
                errorMessage: "Maximum value is \(parameter ?? "0")"
            )
        case "range":
            return ValidationRule(
                type: .range,
                parameter: parameter,
                errorMessage: "Value out of range"
            )
        case "numeric":
            return ValidationRule(
                type: .numeric,
                parameter: nil,
                errorMessage: "Must be numeric"
            )
        case "alphanumeric":
            return ValidationRule(
                type: .alphanumeric,
                parameter: nil,
                errorMessage: "Must be alphanumeric"
            )
        case "custom":
            return ValidationRule(
                type: .custom,
                parameter: parameter,
                errorMessage: "Validation failed"
            )
        default:
            return nil
        }
    }
}

