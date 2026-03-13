import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

@MainActor
@Suite
struct HUDViewModelTests {
    @Test
    func collapsedStateKeepsDetailsVisibleWithoutExpandedMode() {
        let settings = Self.makeSettingsStore(suite: "HUDViewModelTests-collapsed")
        let store = Self.makeUsageStore(settings: settings)
        let now = Date(timeIntervalSince1970: 1_778_000_000)

        store._setSnapshotForTesting(
            UsageSnapshot(
                primary: RateWindow(
                    usedPercent: 84,
                    windowMinutes: nil,
                    resetsAt: nil,
                    resetDescription: "Resets in 42m"),
                secondary: RateWindow(
                    usedPercent: 38,
                    windowMinutes: nil,
                    resetsAt: nil,
                    resetDescription: "Weekly resets Sunday"),
                updatedAt: now),
            provider: .codex)
        store._setSnapshotForTesting(
            UsageSnapshot(
                primary: RateWindow(
                    usedPercent: 94,
                    windowMinutes: nil,
                    resetsAt: nil,
                    resetDescription: "Resets 12:59pm (Europe/London)"),
                secondary: nil,
                updatedAt: now),
            provider: .claude)

        let state = HUDViewModel(store: store, settings: settings, mode: .collapsed).state

        #expect(state.mode == .collapsed)
        #expect(state.showsProviderDetails)
        #expect(state.showsFooter)
        #expect(state.titleText == "Live usage")
        #expect(state.subtitleText.isEmpty)
        #expect(state.providers.count == 2)
        #expect(state.providers.allSatisfy { !$0.secondaryText.isEmpty })
        #expect(state.providers.first(where: { $0.provider == .codex })?.secondaryValue == 38)
        #expect(state.providers.first(where: { $0.provider == .codex })?.secondaryDetailText == "Weekly cap")
        #expect(state.providers.first(where: { $0.provider == .claude })?.secondaryValue == nil)
        #expect(state.providers.first(where: { $0.provider == .codex })?.primaryDetailText == "5-hour session")
        #expect(state.providers.first(where: { $0.provider == .codex })?.secondaryText.contains("Session") == true)
    }

    @Test
    func tuckedStateHidesSupportingDetails() {
        let settings = Self.makeSettingsStore(suite: "HUDViewModelTests-tucked")
        let store = Self.makeUsageStore(settings: settings)

        let state = HUDViewModel(store: store, settings: settings, mode: .tucked).state

        #expect(!state.showsProviderDetails)
        #expect(!state.showsFooter)
    }

    private static func makeSettingsStore(suite: String) -> SettingsStore {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)

        return SettingsStore(
            userDefaults: defaults,
            configStore: configStore,
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore(),
            codexCookieStore: InMemoryCookieHeaderStore(),
            claudeCookieStore: InMemoryCookieHeaderStore(),
            cursorCookieStore: InMemoryCookieHeaderStore(),
            opencodeCookieStore: InMemoryCookieHeaderStore(),
            factoryCookieStore: InMemoryCookieHeaderStore(),
            minimaxCookieStore: InMemoryMiniMaxCookieStore(),
            minimaxAPITokenStore: InMemoryMiniMaxAPITokenStore(),
            kimiTokenStore: InMemoryKimiTokenStore(),
            kimiK2TokenStore: InMemoryKimiK2TokenStore(),
            augmentCookieStore: InMemoryCookieHeaderStore(),
            ampCookieStore: InMemoryCookieHeaderStore(),
            copilotTokenStore: InMemoryCopilotTokenStore(),
            tokenAccountStore: InMemoryTokenAccountStore())
    }

    private static func makeUsageStore(settings: SettingsStore) -> UsageStore {
        UsageStore(
            fetcher: UsageFetcher(environment: [:]),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings)
    }
}
