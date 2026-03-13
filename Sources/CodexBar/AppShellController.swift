import CodexBarCore

@MainActor
protocol AppShellControlling: AnyObject {
    func handlePrimaryShortcut()
}

@MainActor
enum AppShellControllerFactory {
    typealias Factory = (UsageStore, SettingsStore, AccountInfo, UpdaterProviding, PreferencesSelection)
        -> AppShellControlling

    static let defaultFactory: Factory = { store, settings, account, updater, selection in
        _ = account
        _ = updater
        _ = selection
        return HUDWindowController(store: store, settings: settings)
    }

    static var factory: Factory = AppShellControllerFactory.defaultFactory
}
