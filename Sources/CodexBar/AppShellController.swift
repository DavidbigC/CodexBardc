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
        StatusItemAppShellController(
            statusController: StatusItemController.factory(
                store,
                settings,
                account,
                updater,
                selection))
    }

    static var factory: Factory = AppShellControllerFactory.defaultFactory
}

@MainActor
private final class StatusItemAppShellController: AppShellControlling {
    private let statusController: StatusItemControlling

    init(statusController: StatusItemControlling) {
        self.statusController = statusController
    }

    func handlePrimaryShortcut() {
        self.statusController.openMenuFromShortcut()
    }
}
