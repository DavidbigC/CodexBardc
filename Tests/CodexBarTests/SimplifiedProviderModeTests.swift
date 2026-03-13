import CodexBarCore
import Testing
@testable import CodexBar

@MainActor
@Suite
struct SimplifiedProviderModeTests {
    @Test
    func providerRegistryOnlyExposesCodexAndClaude() {
        let registry = ProviderRegistry()

        #expect(registry.metadata.keys.sorted { $0.rawValue < $1.rawValue } == [.claude, .codex])
    }

    @Test
    func settingsDefaultOrderOnlyIncludesCodexAndClaude() {
        let settings = SettingsStore(
            userDefaults: UserDefaults(suiteName: "SimplifiedProviderModeTests") ?? .standard,
            configStore: testConfigStore(suiteName: "SimplifiedProviderModeTests"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())

        #expect(settings.orderedProviders() == [.codex, .claude])
    }

    @Test
    func simplifiedModePrefersAutoDataSourcesWhileKeepingWebDisabled() {
        let suite = "SimplifiedProviderModeTests-auto-sources"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let settings = SettingsStore(
            userDefaults: defaults,
            configStore: testConfigStore(suiteName: suite),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())

        #expect(settings.codexUsageDataSource == .auto)
        #expect(settings.claudeUsageDataSource == .auto)
        #expect(settings.codexCookieSource == .off)
        #expect(settings.claudeCookieSource == .off)
        #expect(settings.openAIWebAccessEnabled == false)
        #expect(settings.claudeWebExtrasEnabled == false)
        #expect(settings.debugDisableKeychainAccess)
        #expect(settings.claudeOAuthKeychainPromptMode == .never)
    }
}
