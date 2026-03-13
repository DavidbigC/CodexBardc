# Floating HUD Design

## Goal
Build a simplified macOS-native CodexBar variant that only tracks Codex and Claude Code usage and presents it as an always-on-top floating HUD instead of a status bar item.

## Product Shape
- The widget is a persistent HUD that stays above normal apps and appears across Spaces.
- The default state is a compact pill that shows Codex and Claude usage side by side.
- Clicking the pill expands it into a larger details card.
- The HUD can be tucked away when needed into a smaller edge-docked state.
- The widget remembers its on-screen position and tuck state between launches.

## Scope

### Keep
- Codex usage fetching via CLI JSON-RPC, with CLI PTY `/status` fallback
- Claude usage fetching via CLI PTY (`/usage` and optional `/status`)
- Shared normalization and refresh pipeline
- Auto-refresh
- Compact and expanded HUD states
- Drag-to-move positioning
- Edge tuck/collapse behavior
- Persistent placement and mode

### Remove Or Defer
- Menu bar status item UI
- Widget extension
- CLI surface area unless it remains required by the provider fetchers
- Merge-icons mode
- Multi-provider UI and settings for providers other than Codex and Claude
- Sparkle/updater work unless needed to keep the app building
- OpenAI web dashboard scraping
- Browser cookie import and manual cookie-header flows
- Claude web API and Claude OAuth fallback paths
- Most Keychain-backed token and cookie storage
- Local cost-history scans unless they are needed later for token details

## Architecture

### App shell
- Replace the status-item-first shell with a floating window shell.
- Use an AppKit-managed `NSPanel` for the widget container.
- Embed SwiftUI views inside the panel for rendering and interaction.

### Data layer
- Reuse `CodexBarCore` provider logic where possible.
- Keep a single store for normalized usage snapshots.
- Limit the active providers to Codex and Claude in the simplified app.
- Prefer local CLI-based probes over browser or OAuth integrations.
- For Codex, use CLI JSON-RPC first and PTY `/status` as fallback.
- For Claude, use CLI PTY as the only active v1 data source.

### UI state
- `collapsed`: compact pill with both providers visible
- `expanded`: larger detail card with deeper stats
- `tucked`: minimized edge-docked state that is still visible and clickable

## Interaction Model

### Collapsed
- Small horizontal pill
- Shows one compact summary for Codex and one for Claude
- Each summary should communicate current usage at a glance with minimal text

### Expanded
- Larger card anchored from the compact HUD
- One section per provider
- Shows:
  - current usage progress
  - reset time
  - last updated time
  - disconnected or stale state
  - any extra details exposed directly by the chosen CLI source

### Deferred detail metrics
- Token totals and richer cost history are deferred unless the existing local scanners can be added without pulling the old app’s broader complexity back in.
- V1 should prioritize reliable live quota state over historical accounting.

### Tucked
- Reduced pill or slim edge-docked sliver
- Remains visible and clickable
- Expands or restores on click

## Window Behavior
- Always on top of standard app windows
- Visible across Spaces
- Draggable
- Position persists
- Expansion should not create a full app-style window chrome
- The HUD should avoid disruptive focus changes where possible, but expanded content can still be interactive

## Error Handling
- If one provider fails, the other continues to render
- Stale data is shown as stale, not as fresh
- Missing auth or unavailable CLI should show a compact disconnected state
- Refresh failures should not interrupt the user with modal UI
- CLI-specific errors should surface as concise provider status text rather than login workflows

## Testing Strategy
- Preserve and extend provider parsing tests for Codex and Claude
- Add view-model tests for collapsed, expanded, and tucked display states
- Add lightweight persistence tests for stored position and mode
- Delay UI automation until the first working HUD shell exists

## Implementation Notes
- The safest refactor is to preserve the provider pipeline and replace the shell around it.
- `NSStatusItem` concerns should be isolated and removed from the simplified app path.
- `NSPanel` behavior should be centralized in a dedicated controller rather than spread across views.
- The simplification target is not "all CodexBar features in a new UI"; it is "a small HUD around the Codex and Claude CLI probes."
- Keychain, cookie, browser, and dashboard code should be treated as opt-in legacy surface area and avoided in the active path unless a hard dependency emerges.

## Success Criteria
- The app launches into a floating always-on-top HUD
- The HUD shows Codex and Claude usage without a menu bar dependency
- Clicking expands into a useful details card
- The HUD can be tucked away and restored
- Position and display mode persist across relaunches
