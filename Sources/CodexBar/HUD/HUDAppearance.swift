import SwiftUI

enum HUDAppearanceStyle: String, CaseIterable, Identifiable {
    case dark
    case light

    var id: String {
        self.rawValue
    }

    var label: String {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        }
    }
}

enum HUDAppearanceAccent: String, CaseIterable, Identifiable {
    case system
    case codex
    case claude
    case mint
    case amber

    var id: String {
        self.rawValue
    }

    var label: String {
        switch self {
        case .system: "System"
        case .codex: "Codex Green"
        case .claude: "Claude Orange"
        case .mint: "Mint"
        case .amber: "Amber"
        }
    }

    var color: Color {
        switch self {
        case .system: .accentColor
        case .codex: Color(red: 0.18, green: 0.80, blue: 0.38)
        case .claude: Color(red: 0.96, green: 0.56, blue: 0.23)
        case .mint: Color(red: 0.24, green: 0.84, blue: 0.72)
        case .amber: Color(red: 0.95, green: 0.73, blue: 0.22)
        }
    }
}
