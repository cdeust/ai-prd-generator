import Foundation

/// UI component type for mockup analysis
public enum ComponentType: String, Sendable, Codable, CaseIterable {
    // Input Components
    case textField = "Text Field"
    case passwordField = "Password Field"
    case searchField = "Search Field"
    case textArea = "Text Area"
    case picker = "Picker"
    case datePicker = "Date Picker"
    case slider = "Slider"
    case stepper = "Stepper"
    case toggle = "Toggle"
    case checkbox = "Checkbox"
    case radioButton = "Radio Button"

    // Action Components
    case button = "Button"
    case iconButton = "Icon Button"
    case link = "Link"
    case menuItem = "Menu Item"

    // Display Components
    case label = "Label"
    case heading = "Heading"
    case image = "Image"
    case icon = "Icon"
    case badge = "Badge"
    case avatar = "Avatar"

    // Container Components
    case card = "Card"
    case list = "List"
    case grid = "Grid"
    case table = "Table"
    case section = "Section"
    case panel = "Panel"
    case modal = "Modal"
    case sheet = "Sheet"
    case popover = "Popover"

    // Navigation Components
    case tabBar = "Tab Bar"
    case navigationBar = "Navigation Bar"
    case sidebar = "Sidebar"
    case breadcrumb = "Breadcrumb"
    case pagination = "Pagination"

    // Feedback Components
    case alert = "Alert"
    case toast = "Toast"
    case progressBar = "Progress Bar"
    case spinner = "Spinner"
    case skeleton = "Skeleton"

    // Other
    case divider = "Divider"
    case spacer = "Spacer"
    case unknown = "Unknown"
}
