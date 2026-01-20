import Foundation

/// Type of screen
public enum ScreenType: String, Sendable, Codable {
    case splash = "Splash"
    case onboarding = "Onboarding"
    case login = "Login"
    case signup = "Signup"
    case home = "Home"
    case list = "List"
    case detail = "Detail"
    case form = "Form"
    case settings = "Settings"
    case profile = "Profile"
    case search = "Search"
    case filter = "Filter"
    case cart = "Cart"
    case checkout = "Checkout"
    case confirmation = "Confirmation"
    case error = "Error"
    case empty = "Empty"
    case loading = "Loading"
    case modal = "Modal"
    case sheet = "Sheet"
}
