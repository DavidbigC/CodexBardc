# Floating HUD Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the menu-bar-first CodexBar shell with a simplified always-on-top floating HUD that only shows Codex and Claude Code usage, supports collapsed/expanded/tucked states, and uses the local CLI-based data paths only.

**Architecture:** Keep `CodexBarCore` as the provider-fetching and parsing layer, then build a new AppKit-owned `NSPanel` shell in `Sources/CodexBar` with SwiftUI content views. Reduce app scope to Codex and Claude by pruning provider-facing settings and replacing `StatusItemController` as the primary presentation path. Codex should use CLI JSON-RPC first with PTY `/status` fallback; Claude should use CLI PTY only.

**Tech Stack:** Swift 6.2, SwiftUI, AppKit (`NSPanel`), Observation, Swift Testing / XCTest, Swift Package Manager

---

### Task 1: Establish the simplified shell boundary

**Files:**
- Modify: `Package.swift`
- Modify: `Sources/CodexBar/CodexbarApp.swift`
- Modify: `docs/architecture.md`
- Test: `swift test --filter CodexBarTests`

**Step 1: Write the failing test**

Add a focused app-shell test in `Tests/CodexBarTests` that asserts the app bootstrap path can create the shared `UsageStore` without constructing a `StatusItemController` when the HUD mode is enabled.

```swift
@Test
func appBootstrapUsesHUDShell() async throws {
    let settings = SettingsStore()
    let fetcher = UsageFetcher()
    let store = UsageStore(
        fetcher: fetcher,
        browserDetection: BrowserDetection(cacheTTL: 0),
        settings: settings,
        startupBehavior: .testing)

    #expect(store.snapshots.isEmpty)
    #expect(StatusItemController.factory != StatusItemController.defaultFactory)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter appBootstrapUsesHUDShell`
Expected: FAIL because the current bootstrap still wires the menu bar shell.

**Step 3: Write minimal implementation**

- Add a dedicated HUD shell bootstrap path in `Sources/CodexBar/CodexbarApp.swift`.
- Move menu-bar-specific setup behind an adapter so the app can instantiate the HUD shell instead.
- Leave `StatusItemController` present temporarily, but stop making it the default entry path.

**Step 4: Run test to verify it passes**

Run: `swift test --filter appBootstrapUsesHUDShell`
Expected: PASS

**Step 5: Commit**

```bash
git add Package.swift Sources/CodexBar/CodexbarApp.swift docs/architecture.md Tests/CodexBarTests
git commit -m "refactor: prepare app shell for floating hud"
```

### Task 2: Restrict the app to Codex and Claude providers

**Files:**
- Modify: `Sources/CodexBar/ProviderRegistry.swift`
- Modify: `Sources/CodexBar/SettingsStore.swift`
- Modify: `Sources/CodexBar/SettingsStore+Defaults.swift`
- Modify: `Sources/CodexBar/UsageStore.swift`
- Modify: `Sources/CodexBarCore/Providers/Providers.swift`
- Modify: `Sources/CodexBarCore/UsageFetcher.swift`
- Test: `Tests/CodexBarTests`

**Step 1: Write the failing test**

Add a provider-scope test that asserts the simplified build only exposes Codex and Claude in the active provider list and initial UI-facing state.

```swift
@Test
func simplifiedModeOnlyUsesCodexAndClaude() async throws {
    let settings = SettingsStore()
    let store = UsageStore(
        fetcher: UsageFetcher(),
        browserDetection: BrowserDetection(cacheTTL: 0),
        settings: settings,
        startupBehavior: .testing)

    let providers = store.providerMetadata.keys.sorted { $0.rawValue < $1.rawValue }
    #expect(providers == [.claude, .codex])
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter simplifiedModeOnlyUsesCodexAndClaude`
Expected: FAIL because the current app registers many providers.

**Step 3: Write minimal implementation**

- Introduce a simplified provider mode that exposes only `.codex` and `.claude`.
- Remove or bypass unrelated provider toggles, ordering, and switcher assumptions in app-facing settings.
- Keep core provider parsing code intact where it does not force extra UI complexity.
- Freeze the active data-source choices to:
  - Codex: CLI JSON-RPC with PTY `/status` fallback
  - Claude: CLI PTY only
- Bypass browser, dashboard, cookie, OAuth, and most Keychain-dependent paths from the active simplified app flow.

**Step 4: Run test to verify it passes**

Run: `swift test --filter simplifiedModeOnlyUsesCodexAndClaude`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CodexBar/ProviderRegistry.swift Sources/CodexBar/SettingsStore.swift Sources/CodexBar/SettingsStore+Defaults.swift Sources/CodexBar/UsageStore.swift Sources/CodexBarCore/Providers/Providers.swift Sources/CodexBarCore/UsageFetcher.swift Tests/CodexBarTests
git commit -m "refactor: simplify providers to codex and claude cli flows"
```

### Task 3: Add HUD panel infrastructure

**Files:**
- Create: `Sources/CodexBar/HUD/HUDWindowController.swift`
- Create: `Sources/CodexBar/HUD/HUDWindow.swift`
- Create: `Sources/CodexBar/HUD/HUDPersistence.swift`
- Modify: `Sources/CodexBar/CodexbarApp.swift`
- Test: `Tests/CodexBarTests/HUDWindowControllerTests.swift`

**Step 1: Write the failing test**

Add tests for panel configuration and persistence defaults.

```swift
@Test
@MainActor
func hudPanelDefaultsToAlwaysOnTopAcrossSpaces() async throws {
    let controller = HUDWindowController.testInstance()

    #expect(controller.panel.level == .statusBar)
    #expect(controller.panel.collectionBehavior.contains(.canJoinAllSpaces))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter hudPanelDefaultsToAlwaysOnTopAcrossSpaces`
Expected: FAIL because no HUD controller exists yet.

**Step 3: Write minimal implementation**

- Introduce an AppKit `NSPanel` subclass or configured instance for the floating HUD.
- Set always-on-top level and all-Spaces behavior.
- Add persistence for position, dock edge, and display mode.
- Wire the app bootstrap to create and show the HUD controller at launch.

**Step 4: Run test to verify it passes**

Run: `swift test --filter hudPanelDefaultsToAlwaysOnTopAcrossSpaces`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CodexBar/HUD/HUDWindowController.swift Sources/CodexBar/HUD/HUDWindow.swift Sources/CodexBar/HUD/HUDPersistence.swift Sources/CodexBar/CodexbarApp.swift Tests/CodexBarTests/HUDWindowControllerTests.swift
git commit -m "feat: add floating hud panel shell"
```

### Task 4: Build the HUD state model and view model

**Files:**
- Create: `Sources/CodexBar/HUD/HUDViewModel.swift`
- Create: `Sources/CodexBar/HUD/HUDModels.swift`
- Modify: `Sources/CodexBar/UsageStore+Accessors.swift`
- Modify: `Sources/CodexBar/UsageStore+Status.swift`
- Test: `Tests/CodexBarTests/HUDViewModelTests.swift`

**Step 1: Write the failing test**

Add state-derivation tests for collapsed, expanded, and tucked display models.

```swift
@Test
@MainActor
func collapsedHUDShowsBothProviders() async throws {
    let store = TestUsageStoreFactory.withSnapshots([
        .codex: .fixture(primaryUsed: 25, updatedAt: .now),
        .claude: .fixture(primaryUsed: 70, updatedAt: .now),
    ])
    let viewModel = HUDViewModel(store: store)

    let model = viewModel.collapsedModel
    #expect(model.providers.count == 2)
    #expect(model.providers.map(\.provider) == [.codex, .claude])
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter collapsedHUDShowsBothProviders`
Expected: FAIL because the HUD view model does not exist.

**Step 3: Write minimal implementation**

- Add a UI-focused view model that derives compact and detailed state from `UsageStore`.
- Normalize stale, disconnected, and error states into simple display enums.
- Keep rendering logic out of the SwiftUI views.

**Step 4: Run test to verify it passes**

Run: `swift test --filter collapsedHUDShowsBothProviders`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CodexBar/HUD/HUDViewModel.swift Sources/CodexBar/HUD/HUDModels.swift Sources/CodexBar/UsageStore+Accessors.swift Sources/CodexBar/UsageStore+Status.swift Tests/CodexBarTests/HUDViewModelTests.swift
git commit -m "feat: add hud state model"
```

### Task 5: Implement the collapsed and expanded HUD views

**Files:**
- Create: `Sources/CodexBar/HUD/HUDRootView.swift`
- Create: `Sources/CodexBar/HUD/HUDCollapsedView.swift`
- Create: `Sources/CodexBar/HUD/HUDExpandedView.swift`
- Create: `Sources/CodexBar/HUD/HUDProviderCard.swift`
- Modify: `Sources/CodexBar/UsageProgressBar.swift`
- Modify: `Sources/CodexBar/ProviderBrandIcon.swift`
- Test: `Tests/CodexBarTests/HUDViewModelTests.swift`

**Step 1: Write the failing test**

Add rendering-oriented view model assertions for expanded provider detail content.

```swift
@Test
@MainActor
func expandedHUDIncludesTokenAndResetDetails() async throws {
    let store = TestUsageStoreFactory.withSnapshots([
        .codex: .fixture(primaryUsed: 55, updatedAt: .now),
    ])
    let viewModel = HUDViewModel(store: store)

    let details = viewModel.expandedModel.providers.first(where: { $0.provider == .codex })
    #expect(details?.resetText != nil)
    #expect(details?.sourceStatusText != nil)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter expandedHUDIncludesTokenAndResetDetails`
Expected: FAIL because the expanded HUD detail model and views do not exist yet.

**Step 3: Write minimal implementation**

- Create a compact pill layout for the collapsed state.
- Create an expanded details card with one section per provider.
- Reuse existing progress-bar and provider icon components where it keeps the code smaller.
- Prefer live quota and source-status details over token-history metrics in v1.

**Step 4: Run test to verify it passes**

Run: `swift test --filter expandedHUDIncludesTokenAndResetDetails`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CodexBar/HUD/HUDRootView.swift Sources/CodexBar/HUD/HUDCollapsedView.swift Sources/CodexBar/HUD/HUDExpandedView.swift Sources/CodexBar/HUD/HUDProviderCard.swift Sources/CodexBar/UsageProgressBar.swift Sources/CodexBar/ProviderBrandIcon.swift Tests/CodexBarTests/HUDViewModelTests.swift
git commit -m "feat: add floating hud views"
```

### Task 6: Implement tuck, drag, and restore interactions

**Files:**
- Modify: `Sources/CodexBar/HUD/HUDWindowController.swift`
- Modify: `Sources/CodexBar/HUD/HUDPersistence.swift`
- Modify: `Sources/CodexBar/HUD/HUDRootView.swift`
- Test: `Tests/CodexBarTests/HUDWindowControllerTests.swift`

**Step 1: Write the failing test**

Add persistence and docking behavior tests.

```swift
@Test
@MainActor
func tuckedHUDRestoresSavedEdgeAndMode() async throws {
    let persistence = HUDPersistence(userDefaults: .suite(named: "HUDTests")!)
    persistence.save(mode: .tucked, edge: .right, origin: CGPoint(x: 1400, y: 500))

    let restored = persistence.loadState()
    #expect(restored.mode == .tucked)
    #expect(restored.edge == .right)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter tuckedHUDRestoresSavedEdgeAndMode`
Expected: FAIL until tuck state persistence exists.

**Step 3: Write minimal implementation**

- Support dragging the panel.
- Detect edge docking or explicit tuck requests.
- Persist and restore tucked state and position.
- Ensure click-to-expand still works from tucked mode.

**Step 4: Run test to verify it passes**

Run: `swift test --filter tuckedHUDRestoresSavedEdgeAndMode`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CodexBar/HUD/HUDWindowController.swift Sources/CodexBar/HUD/HUDPersistence.swift Sources/CodexBar/HUD/HUDRootView.swift Tests/CodexBarTests/HUDWindowControllerTests.swift
git commit -m "feat: add hud tuck and position persistence"
```

### Task 7: Remove menu bar dependencies from the simplified app path

**Files:**
- Modify: `Sources/CodexBar/AppDelegate.swift` or the file containing delegate configuration
- Modify: `Sources/CodexBar/StatusItemController.swift`
- Modify: `Sources/CodexBar/MenuContent.swift`
- Modify: `Sources/CodexBar/MenuCardView.swift`
- Modify: `Package.swift`
- Test: `swift test --filter CodexBarTests`

**Step 1: Write the failing test**

Add a shell-level test that asserts the simplified app can launch without constructing menus or status items.

```swift
@Test
@MainActor
func simplifiedHUDDoesNotRequireStatusItems() async throws {
    let harness = AppShellHarness.makeHUDOnly()
    #expect(harness.statusItemController == nil)
    #expect(harness.hudController != nil)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter simplifiedHUDDoesNotRequireStatusItems`
Expected: FAIL because the app still assumes status-item infrastructure.

**Step 3: Write minimal implementation**

- Move remaining menu-bar-only setup behind simplified-app feature boundaries.
- Remove unnecessary menu rendering and provider switcher dependencies from the active path.
- Keep dead code cleanup incremental so the app still builds after each step.

**Step 4: Run test to verify it passes**

Run: `swift test --filter simplifiedHUDDoesNotRequireStatusItems`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/CodexBar Sources/CodexBarCore Package.swift Tests/CodexBarTests
git commit -m "refactor: remove menu bar dependencies from simplified app"
```

### Task 8: Verify refresh, persistence, and launch behavior end-to-end

**Files:**
- Modify: `Tests/CodexBarTests`
- Modify: `docs/DEVELOPMENT.md`
- Modify: `docs/plans/2026-03-13-floating-hud-design.md`
- Test: `swift test`

**Step 1: Write the failing test**

Add a focused integration test that verifies launch state, provider rendering, and persistence restore through the HUD view model/controller boundary.

```swift
@Test
@MainActor
func hudLaunchRestoresStateAndShowsProviderSummaries() async throws {
    let harness = HUDIntegrationHarness.savedTuckedState()
    let result = await harness.launch()

    #expect(result.mode == .tucked)
    #expect(result.providers == [.codex, .claude])
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter hudLaunchRestoresStateAndShowsProviderSummaries`
Expected: FAIL until the shell, persistence, and model wiring are complete.

**Step 3: Write minimal implementation**

- Fill in any remaining launch wiring gaps.
- Update development docs with the new HUD-first architecture and run instructions.
- Confirm the simplified app starts cleanly and refreshes both providers through the chosen CLI-based paths.

**Step 4: Run test to verify it passes**

Run: `swift test`
Expected: PASS

**Step 5: Commit**

```bash
git add Tests/CodexBarTests docs/DEVELOPMENT.md docs/plans/2026-03-13-floating-hud-design.md
git commit -m "test: verify floating hud launch behavior"
```
