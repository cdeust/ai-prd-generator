// Vision components require Apple platforms
#if os(macOS) || os(iOS)
import Domain

/// Component type categorization helpers
extension ComponentType {
    var isDisplayOnly: Bool {
        switch self {
        case .label, .heading, .image, .icon, .badge, .avatar, .divider, .spacer:
            return true
        default:
            return false
        }
    }

    var isInputField: Bool {
        switch self {
        case .textField, .passwordField, .searchField, .textArea, .picker, .datePicker:
            return true
        default:
            return false
        }
    }
}

#endif // os(macOS) || os(iOS)
