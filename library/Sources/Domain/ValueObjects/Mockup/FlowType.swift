import Foundation

/// Type of user flow
public enum FlowType: String, Sendable, Codable {
    case primary = "Primary"
    case secondary = "Secondary"
    case error = "Error"
    case onboarding = "Onboarding"
    case authentication = "Authentication"
    case payment = "Payment"
    case settings = "Settings"
    case help = "Help"
}
