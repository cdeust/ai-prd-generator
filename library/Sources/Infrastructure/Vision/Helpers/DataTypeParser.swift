import Foundation
import Domain

/// Parses string data types to DataType enum
struct DataTypeParser: Sendable {
    func parse(_ typeString: String) -> DataType {
        let normalized = typeString.lowercased()

        if let basicType = parseBasicTypes(normalized) {
            return basicType
        }

        if let numericType = parseNumericTypes(normalized) {
            return numericType
        }

        if let mediaType = parseMediaTypes(normalized) {
            return mediaType
        }

        if let locationType = parseLocationTypes(normalized) {
            return locationType
        }

        return .text
    }

    private func parseBasicTypes(_ type: String) -> DataType? {
        switch type {
        case "text", "string":
            return .text
        case "email":
            return .email
        case "password":
            return .password
        case "url":
            return .url
        case "phone", "phonenumber":
            return .phone
        case "boolean", "bool":
            return .boolean
        default:
            return nil
        }
    }

    private func parseNumericTypes(_ type: String) -> DataType? {
        switch type {
        case "number":
            return .number
        case "integer", "int":
            return .integer
        case "decimal", "float":
            return .decimal
        case "currency", "money":
            return .currency
        default:
            return nil
        }
    }

    private func parseMediaTypes(_ type: String) -> DataType? {
        switch type {
        case "file":
            return .file
        case "image":
            return .image
        case "video":
            return .video
        case "audio":
            return .audio
        default:
            return nil
        }
    }

    private func parseLocationTypes(_ type: String) -> DataType? {
        switch type {
        case "date":
            return .date
        case "datetime", "timestamp":
            return .datetime
        case "time":
            return .time
        case "json":
            return .json
        case "array", "list":
            return .array
        case "location", "coordinates", "latlng":
            return .location
        case "address":
            return .address
        case "zipcode", "zip", "postalcode":
            return .zipCode
        case "country":
            return .country
        case "state", "province":
            return .state
        case "city":
            return .city
        case "custom":
            return .custom
        default:
            return nil
        }
    }
}
