import CodexBarCore

enum SimplifiedAppProviders {
    static let active: [UsageProvider] = [
        .codex,
        .claude,
    ]

    static let activeSet = Set(active)
}
