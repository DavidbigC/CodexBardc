import AppKit
import Testing
@testable import CodexBar

@MainActor
@Suite
struct HUDPersistenceTests {
    @Test
    func savesAndLoadsExpandedSize() throws {
        let suite = "HUDPersistenceTests-size"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let persistence = HUDPersistence(userDefaults: defaults)
        persistence.save(
            mode: .collapsed,
            origin: CGPoint(x: 120, y: 240),
            size: CGSize(width: 360, height: 280))

        let loaded = persistence.loadState()

        #expect(loaded.mode == .collapsed)
        #expect(loaded.origin?.x == 120)
        #expect(loaded.origin?.y == 240)
        #expect(loaded.size?.width == 360)
        #expect(loaded.size?.height == 280)
    }
}
