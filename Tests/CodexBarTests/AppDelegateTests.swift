import AppKit
import CodexBarCore
import Testing
@testable import CodexBar

@MainActor
@Suite
struct AppDelegateTests {
    @Test
    func buildsConfiguredAppShellAfterLaunch() {
        let appDelegate = AppDelegate()
        var factoryCalls = 0

        AppShellControllerFactory.factory = { _, _, _, _, _ in
            factoryCalls += 1
            return DummyAppShellController()
        }
        defer { AppShellControllerFactory.factory = AppShellControllerFactory.defaultFactory }

        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "AppDelegateTests"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        let fetcher = UsageFetcher()
        let store = UsageStore(
            fetcher: fetcher,
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            startupBehavior: .testing)
        let account = fetcher.loadAccountInfo()

        // configure should not eagerly construct the app shell
        appDelegate.configure(store: store, settings: settings, account: account, selection: PreferencesSelection())
        #expect(factoryCalls == 0)

        // construction happens once after launch
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        #expect(factoryCalls == 1)

        // idempotent on subsequent calls
        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        #expect(factoryCalls == 1)
    }
}

@MainActor
private final class DummyAppShellController: AppShellControlling {
    func handlePrimaryShortcut() {}
}
