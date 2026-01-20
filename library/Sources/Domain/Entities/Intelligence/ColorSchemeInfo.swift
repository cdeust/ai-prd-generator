import Foundation

/// Color scheme information from mockup analysis
public struct ColorSchemeInfo: Sendable, Codable {
    public let primary: String?
    public let secondary: String?
    public let accent: String?
    public let background: String?
    public let text: String?
    public let isDarkMode: Bool?

    public init(
        primary: String? = nil,
        secondary: String? = nil,
        accent: String? = nil,
        background: String? = nil,
        text: String? = nil,
        isDarkMode: Bool? = nil
    ) {
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.background = background
        self.text = text
        self.isDarkMode = isDarkMode
    }
}
