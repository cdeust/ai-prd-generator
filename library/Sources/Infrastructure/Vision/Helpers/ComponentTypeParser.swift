import Foundation
import Domain

/// Parses string component types to ComponentType enum
struct ComponentTypeParser: Sendable {
    func parse(_ typeString: String) -> ComponentType {
        let normalized = typeString.lowercased().replacingOccurrences(of: "_", with: "")

        if let inputType = parseInputTypes(normalized) {
            return inputType
        }

        if let actionType = parseActionTypes(normalized) {
            return actionType
        }

        if let displayType = parseDisplayTypes(normalized) {
            return displayType
        }

        if let containerType = parseContainerTypes(normalized) {
            return containerType
        }

        if let navType = parseNavigationTypes(normalized) {
            return navType
        }

        if let feedbackType = parseFeedbackTypes(normalized) {
            return feedbackType
        }

        if let otherType = parseOtherTypes(normalized) {
            return otherType
        }

        return .unknown
    }

    private func parseInputTypes(_ type: String) -> ComponentType? {
        switch type {
        case "textfield", "text field", "input":
            return .textField
        case "passwordfield", "password field", "password":
            return .passwordField
        case "searchfield", "search field", "search":
            return .searchField
        case "textarea", "text area":
            return .textArea
        case "picker":
            return .picker
        case "datepicker", "date picker":
            return .datePicker
        case "slider":
            return .slider
        case "stepper":
            return .stepper
        case "toggle", "switch":
            return .toggle
        case "checkbox":
            return .checkbox
        case "radiobutton", "radio button", "radio":
            return .radioButton
        default:
            return nil
        }
    }

    private func parseActionTypes(_ type: String) -> ComponentType? {
        switch type {
        case "button":
            return .button
        case "iconbutton", "icon button":
            return .iconButton
        case "link":
            return .link
        case "menuitem", "menu item":
            return .menuItem
        default:
            return nil
        }
    }

    private func parseDisplayTypes(_ type: String) -> ComponentType? {
        switch type {
        case "label":
            return .label
        case "heading":
            return .heading
        case "image":
            return .image
        case "icon":
            return .icon
        case "badge":
            return .badge
        case "avatar":
            return .avatar
        default:
            return nil
        }
    }

    private func parseContainerTypes(_ type: String) -> ComponentType? {
        switch type {
        case "card":
            return .card
        case "list":
            return .list
        case "grid":
            return .grid
        case "table":
            return .table
        case "section":
            return .section
        case "panel":
            return .panel
        case "modal":
            return .modal
        case "sheet":
            return .sheet
        case "popover":
            return .popover
        default:
            return nil
        }
    }

    private func parseNavigationTypes(_ type: String) -> ComponentType? {
        switch type {
        case "tabbar", "tab bar":
            return .tabBar
        case "navigationbar", "navigation bar":
            return .navigationBar
        case "sidebar":
            return .sidebar
        case "breadcrumb":
            return .breadcrumb
        case "pagination":
            return .pagination
        default:
            return nil
        }
    }

    private func parseFeedbackTypes(_ type: String) -> ComponentType? {
        switch type {
        case "alert":
            return .alert
        case "toast":
            return .toast
        case "progressbar", "progress bar":
            return .progressBar
        case "spinner", "loading":
            return .spinner
        case "skeleton":
            return .skeleton
        default:
            return nil
        }
    }

    private func parseOtherTypes(_ type: String) -> ComponentType? {
        switch type {
        case "divider":
            return .divider
        case "spacer":
            return .spacer
        default:
            return nil
        }
    }
}
