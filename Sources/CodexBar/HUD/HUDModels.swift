import CodexBarCore
import Foundation

struct HUDProviderSummary: Identifiable {
    let provider: UsageProvider
    let title: String
    let sourceLabel: String
    let primaryValueText: String?
    let primaryValue: Double?
    let primaryDetailText: String
    let secondaryValueText: String?
    let secondaryValue: Double?
    let secondaryDetailText: String?
    let secondaryText: String
    let tint: HUDTint

    var id: UsageProvider {
        self.provider
    }
}

struct HUDViewState {
    let mode: HUDDisplayMode
    let providers: [HUDProviderSummary]
    let lastUpdatedText: String
    let refreshText: String
    let titleText: String
    let subtitleText: String
    let showsProviderDetails: Bool
    let showsFooter: Bool
    let isRefreshing: Bool
    let opacity: Double
    let scale: Double
    let style: HUDAppearanceStyle
    let accent: HUDAppearanceAccent
}

enum HUDTint {
    case codex
    case claude
}
