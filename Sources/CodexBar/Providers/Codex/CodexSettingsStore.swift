import CodexBarCore
import Foundation

extension SettingsStore {
    var codexUsageDataSource: CodexUsageDataSource {
        get {
            let source = self.configSnapshot.providerConfig(for: .codex)?.source
            return Self.codexUsageDataSource(from: source)
        }
        set {
            let source: ProviderSourceMode = switch newValue {
            case .auto: .auto
            case .oauth: .oauth
            case .cli: .cli
            }
            self.updateProviderConfig(provider: .codex) { entry in
                entry.source = source
            }
            self.logProviderModeChange(provider: .codex, field: "usageSource", value: newValue.rawValue)
        }
    }

    var codexCookieHeader: String {
        get { "" }
        set { _ = newValue }
    }

    var codexCookieSource: ProviderCookieSource {
        get { .off }
        set { _ = newValue }
    }

    func ensureCodexCookieLoaded() {}
}

extension SettingsStore {
    func codexSettingsSnapshot(tokenOverride: TokenAccountOverride?) -> ProviderSettingsSnapshot.CodexProviderSettings {
        _ = tokenOverride
        return ProviderSettingsSnapshot.CodexProviderSettings(
            usageDataSource: self.codexUsageDataSource,
            cookieSource: .off,
            manualCookieHeader: "")
    }

    private static func codexUsageDataSource(from source: ProviderSourceMode?) -> CodexUsageDataSource {
        guard let source else { return .auto }
        switch source {
        case .auto, .web:
            return .auto
        case .oauth:
            return .oauth
        case .cli, .api:
            return .cli
        }
    }
}
