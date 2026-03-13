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
}
