import AppKit
import CodexBarCore
import SwiftUI

@MainActor
final class HUDWindowController: NSWindowController, NSWindowDelegate, AppShellControlling {
    private let store: UsageStore
    private let settings: SettingsStore
    private let persistence: HUDPersistence
    private var mode: HUDDisplayMode

    init(
        store: UsageStore,
        settings: SettingsStore,
        persistence: HUDPersistence = .shared)
    {
        self.store = store
        self.settings = settings
        self.persistence = persistence
        let persisted = persistence.loadState()
        self.mode = persisted.mode

        let frame = HUDWindowController.initialFrame(origin: persisted.origin, mode: persisted.mode)
        let panel = HUDWindow(contentRect: frame)
        super.init(window: panel)
        panel.delegate = self
        panel.contentView = NSHostingView(rootView: self.makeRootView())
        self.showWindow(nil)
        panel.orderFrontRegardless()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handlePrimaryShortcut() {
        self.toggleExpanded()
    }

    func windowDidMove(_ notification: Notification) {
        self.persistState()
    }

    private func toggleExpanded() {
        self.mode = self.mode == .expanded ? .collapsed : .expanded
        self.applyMode()
    }

    private func toggleTucked() {
        self.mode = self.mode == .tucked ? .collapsed : .tucked
        self.applyMode()
    }

    private func applyMode() {
        guard let window else { return }
        let size = Self.size(for: self.mode)
        var frame = window.frame
        frame.size = size
        window.setFrame(frame, display: true, animate: true)
        window.contentView = NSHostingView(rootView: self.makeRootView())
        self.persistState()
    }

    private func persistState() {
        guard let window else { return }
        self.persistence.save(mode: self.mode, origin: window.frame.origin)
    }

    private func makeRootView() -> some View {
        HUDShellView(
            store: self.store,
            settings: self.settings,
            mode: self.mode,
            onToggleExpanded: { self.toggleExpanded() },
            onToggleTucked: { self.toggleTucked() })
    }

    private static func initialFrame(origin: CGPoint?, mode: HUDDisplayMode) -> NSRect {
        let size = self.size(for: mode)
        if let origin {
            return NSRect(origin: origin, size: size)
        }

        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultOrigin = CGPoint(
            x: visibleFrame.maxX - size.width - 28,
            y: visibleFrame.maxY - size.height - 56)
        return NSRect(origin: defaultOrigin, size: size)
    }

    private static func size(for mode: HUDDisplayMode) -> NSSize {
        switch mode {
        case .collapsed:
            NSSize(width: 260, height: 72)
        case .expanded:
            NSSize(width: 360, height: 188)
        case .tucked:
            NSSize(width: 80, height: 52)
        }
    }
}

private struct HUDShellView: View {
    @Bindable var store: UsageStore
    @Bindable var settings: SettingsStore
    let mode: HUDDisplayMode
    let onToggleExpanded: () -> Void
    let onToggleTucked: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Usage HUD")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(self.mode == .tucked ? "Show" : "Tuck", action: self.onToggleTucked)
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if self.mode == .tucked {
                Text("C/C")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .onTapGesture(perform: self.onToggleExpanded)
            } else {
                VStack(spacing: 8) {
                    self.providerRow(.codex, title: "Codex")
                    self.providerRow(.claude, title: "Claude")
                }

                if self.mode == .expanded {
                    Divider().overlay(.white.opacity(0.08))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Refresh: \(self.settings.refreshFrequency.label)")
                        Text("Last update: \(self.lastUpdatedText)")
                    }
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard self.mode != .tucked else { return }
            self.onToggleExpanded()
        }
    }

    private var lastUpdatedText: String {
        let dates = SimplifiedAppProviders.active.compactMap { self.store.snapshots[$0]?.updatedAt }
        guard let latest = dates.max() else { return "No data yet" }
        return UsageFormatter.updatedString(from: latest)
    }

    @ViewBuilder
    private func providerRow(_ provider: UsageProvider, title: String) -> some View {
        let snapshot = self.store.snapshots[provider]
        let window = snapshot?.primary ?? snapshot?.secondary
        let usedPercent = window?.usedPercent
        let resetDescription = window.flatMap {
            UsageFormatter.resetLine(for: $0, style: self.settings.resetTimeDisplayStyle)
        }

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Spacer()
                if let usedPercent {
                    Text("\(Int(usedPercent.rounded()))%")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else if let error = self.store.error(for: provider) {
                    Text(error)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("No data")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { proxy in
                let width = max(0, min(proxy.size.width, proxy.size.width * CGFloat((usedPercent ?? 0) / 100)))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule().fill(provider == .codex ? Color.green.opacity(0.85) : Color.orange.opacity(0.85))
                        .frame(width: width)
                }
            }
            .frame(height: 6)

            if self.mode == .expanded, let resetDescription {
                Text(resetDescription)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
