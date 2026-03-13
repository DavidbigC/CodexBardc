import AppKit
import CodexBarCore
import Observation
import SwiftUI

@MainActor
final class HUDWindowController: NSWindowController, NSWindowDelegate, AppShellControlling {
    private let store: UsageStore
    private let settings: SettingsStore
    private let persistence: HUDPersistence
    private var mode: HUDDisplayMode
    private var expandedSize: CGSize?

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
        self.expandedSize = persisted.size

        let frame = HUDWindowController.initialFrame(
            origin: persisted.origin,
            size: persisted.size,
            mode: persisted.mode)
        let panel = HUDWindow(contentRect: frame)
        super.init(window: panel)
        panel.delegate = self
        panel.contentView = NSHostingView(rootView: self.makeRootView())
        self.configureWindowBehavior(for: panel, mode: self.mode)
        self.observeHUDSettings()
        self.showWindow(nil)
        panel.orderFrontRegardless()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handlePrimaryShortcut() {
        self.toggleTucked()
    }

    private func toggleTucked() {
        self.mode = self.mode == .tucked ? .collapsed : .tucked
        self.applyMode()
    }

    func windowDidMove(_ notification: Notification) {
        self.persistState()
    }

    func windowDidResize(_ notification: Notification) {
        guard let window, self.mode != .tucked else { return }
        self.expandedSize = window.frame.size
        self.persistState()
    }

    private func applyMode() {
        self.applyMode(animated: true)
    }

    private func applyMode(animated: Bool) {
        guard let window else { return }
        let size = self.resolvedSize(for: self.mode)
        var frame = window.frame
        frame.size = size
        self.configureWindowBehavior(for: window, mode: self.mode)
        window.setFrame(frame, display: true, animate: animated)
        window.contentView = NSHostingView(rootView: self.makeRootView())
        self.persistState()
    }

    private func persistState() {
        guard let window else { return }
        let persistedSize = self.mode == .tucked ? self.expandedSize : window.frame.size
        self.persistence.save(mode: self.mode, origin: window.frame.origin, size: persistedSize)
    }

    private func makeRootView() -> some View {
        HUDRootView(
            store: self.store,
            settings: self.settings,
            mode: self.mode,
            onToggleTucked: { self.toggleTucked() },
            onRefresh: { [store = self.store] in
                Task {
                    await ProviderInteractionContext.$current.withValue(.userInitiated) {
                        await store.refresh(forceTokenUsage: true)
                    }
                }
            })
    }

    private static func initialFrame(origin: CGPoint?, size: CGSize?, mode: HUDDisplayMode) -> NSRect {
        let defaultSize = self.defaultSize(for: mode, scale: 1.0)
        let resolvedSize: CGSize = if mode == .tucked {
            self.defaultSize(for: .tucked, scale: 1.0)
        } else if let size {
            CGSize(width: max(size.width, 280), height: max(size.height, 220))
        } else {
            defaultSize
        }
        if let origin {
            return NSRect(origin: origin, size: resolvedSize)
        }

        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultOrigin = CGPoint(
            x: visibleFrame.maxX - resolvedSize.width - 28,
            y: visibleFrame.maxY - resolvedSize.height - 56)
        return NSRect(origin: defaultOrigin, size: resolvedSize)
    }

    private static func defaultSize(for mode: HUDDisplayMode, scale: Double) -> NSSize {
        let scaled = CGFloat(scale)
        switch mode {
        case .collapsed:
            return NSSize(width: 332 * scaled, height: 238 * scaled)
        case .expanded:
            return NSSize(width: 332 * scaled, height: 238 * scaled)
        case .tucked:
            return NSSize(width: 84 * scaled, height: 32 * scaled)
        }
    }

    private func resolvedSize(for mode: HUDDisplayMode) -> NSSize {
        if mode == .tucked {
            return Self.defaultSize(for: .tucked, scale: self.settings.hudScale)
        }
        if let expandedSize {
            return NSSize(width: max(expandedSize.width, 280), height: max(expandedSize.height, 220))
        }
        return Self.defaultSize(for: mode, scale: self.settings.hudScale)
    }

    private func configureWindowBehavior(for window: NSWindow, mode: HUDDisplayMode) {
        if mode == .tucked {
            window.styleMask.remove(.resizable)
            window.minSize = Self.defaultSize(for: .tucked, scale: self.settings.hudScale)
            window.maxSize = Self.defaultSize(for: .tucked, scale: self.settings.hudScale)
        } else {
            window.styleMask.insert(.resizable)
            window.minSize = NSSize(width: 280, height: 220)
            window.maxSize = NSSize(width: 700, height: 720)
        }
    }

    private func observeHUDSettings() {
        withObservationTracking {
            _ = self.settings.hudOpacity
            _ = self.settings.hudScale
            _ = self.settings.hudAppearanceStyle
            _ = self.settings.hudAccent
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.observeHUDSettings()
                guard let window = self.window else { return }
                self.configureWindowBehavior(for: window, mode: self.mode)
                window.contentView = NSHostingView(rootView: self.makeRootView())
            }
        }
    }
}
