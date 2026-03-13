import CodexBarCore
import Foundation

extension SettingsStore {
    var claudeUsageDataSource: ClaudeUsageDataSource {
        get {
            let source = self.configSnapshot.providerConfig(for: .claude)?.source
            return Self.claudeUsageDataSource(from: source)
        }
        set {
            let source: ProviderSourceMode = switch newValue {
            case .auto: .auto
            case .oauth: .oauth
            case .web: .web
            case .cli: .cli
            }
            self.updateProviderConfig(provider: .claude) { entry in
                entry.source = source
            }
            self.logProviderModeChange(provider: .claude, field: "usageSource", value: newValue.rawValue)
            if newValue != .cli {
                self.claudeWebExtrasEnabled = false
            }
        }
    }

    var claudeCookieHeader: String {
        get { "" }
        set { _ = newValue }
    }

    var claudeCookieSource: ProviderCookieSource {
        get { .off }
        set { _ = newValue }
    }

    func ensureClaudeCookieLoaded() {}
}

extension SettingsStore {
    func claudeSettingsSnapshot(tokenOverride: TokenAccountOverride?) -> ProviderSettingsSnapshot
    .ClaudeProviderSettings {
        _ = tokenOverride
        return ProviderSettingsSnapshot.ClaudeProviderSettings(
            usageDataSource: self.claudeUsageDataSource,
            webExtrasEnabled: false,
            cookieSource: .off,
            manualCookieHeader: "")
    }

    private static func claudeUsageDataSource(from source: ProviderSourceMode?) -> ClaudeUsageDataSource {
        guard let source else { return .auto }
        switch source {
        case .auto, .api:
            return .auto
        case .oauth:
            return .oauth
        case .web:
            return .web
        case .cli:
            return .cli
        }
    }
}
