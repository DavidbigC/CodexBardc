import CodexBarCore
import Foundation

@MainActor
struct HUDViewModel {
    private let store: UsageStore
    private let settings: SettingsStore
    private let mode: HUDDisplayMode

    init(store: UsageStore, settings: SettingsStore, mode: HUDDisplayMode) {
        self.store = store
        self.settings = settings
        self.mode = mode
    }

    var state: HUDViewState {
        let showsSupportingContent = self.mode != .tucked
        return HUDViewState(
            mode: self.mode,
            providers: SimplifiedAppProviders.active.map { self.makeProviderSummary(for: $0) },
            lastUpdatedText: self.lastUpdatedText,
            refreshText: "Refresh: \(self.settings.refreshFrequency.label)",
            titleText: "Live usage",
            subtitleText: self.subtitleText,
            showsProviderDetails: showsSupportingContent,
            showsFooter: showsSupportingContent,
            isRefreshing: self.store.isRefreshing,
            opacity: self.settings.hudOpacity,
            scale: self.settings.hudScale,
            style: self.settings.hudAppearanceStyle,
            accent: self.settings.hudAccent)
    }

    private var subtitleText: String {
        if SimplifiedAppProviders.active.contains(where: { self.store.snapshots[$0] != nil }) {
            return ""
        }
        return "Waiting for provider data"
    }

    private var lastUpdatedText: String {
        let dates = SimplifiedAppProviders.active.compactMap { self.store.snapshots[$0]?.updatedAt }
        guard let latest = dates.max() else { return "Last update: No data yet" }
        return "Last update: \(UsageFormatter.updatedString(from: latest))"
    }

    private func makeProviderSummary(for provider: UsageProvider) -> HUDProviderSummary {
        let snapshot = self.store.snapshots[provider]
        let primaryWindow = snapshot?.primary ?? snapshot?.secondary
        let secondaryWindow = provider == .codex ? snapshot?.secondary : nil
        let secondaryText: String
        let primaryDetailText: String

        if let primaryWindow {
            let primaryResetText = UsageFormatter.resetLine(
                for: primaryWindow,
                style: self.settings.resetTimeDisplayStyle) ?? "No reset info"
            if provider == .codex, secondaryWindow != nil {
                secondaryText = "Session \(primaryResetText)"
            } else {
                secondaryText = primaryResetText
            }
            primaryDetailText = provider == .codex
                ? "5-hour session"
                : "\(Int(primaryWindow.usedPercent.rounded()))% used"
        } else if let error = self.store.error(for: provider), !error.isEmpty {
            secondaryText = UsageFormatter.truncatedSingleLine(error, max: 60)
            primaryDetailText = "Unavailable"
        } else {
            secondaryText = "No data"
            primaryDetailText = "Waiting"
        }

        return HUDProviderSummary(
            provider: provider,
            title: provider == .codex ? "Codex" : "Claude",
            sourceLabel: self.store.sourceLabel(for: provider),
            primaryValueText: primaryWindow.map { "\(Int($0.usedPercent.rounded()))%" },
            primaryValue: primaryWindow?.usedPercent,
            primaryDetailText: primaryDetailText,
            secondaryValueText: secondaryWindow.map { "\(Int($0.usedPercent.rounded()))%" },
            secondaryValue: secondaryWindow?.usedPercent,
            secondaryDetailText: secondaryWindow == nil ? nil : "Weekly cap",
            secondaryText: secondaryText,
            tint: provider == .codex ? .codex : .claude)
    }
}
