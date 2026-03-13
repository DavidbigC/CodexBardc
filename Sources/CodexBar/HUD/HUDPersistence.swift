import AppKit

enum HUDDisplayMode: String {
    case collapsed
    case expanded
    case tucked
}

struct HUDStoredState {
    var mode: HUDDisplayMode
    var origin: CGPoint?
}

@MainActor
final class HUDPersistence {
    static let shared = HUDPersistence()

    private let userDefaults: UserDefaults
    private let modeKey = "hud.mode"
    private let originXKey = "hud.origin.x"
    private let originYKey = "hud.origin.y"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadState() -> HUDStoredState {
        let rawMode = self.userDefaults.string(forKey: self.modeKey)
        let mode = HUDDisplayMode(rawValue: rawMode ?? "") ?? .collapsed
        let hasOrigin = self.userDefaults.object(forKey: self.originXKey) != nil &&
            self.userDefaults.object(forKey: self.originYKey) != nil
        let origin: CGPoint? = hasOrigin
            ? CGPoint(
                x: self.userDefaults.double(forKey: self.originXKey),
                y: self.userDefaults.double(forKey: self.originYKey))
            : nil
        return HUDStoredState(mode: mode, origin: origin)
    }

    func save(mode: HUDDisplayMode, origin: CGPoint) {
        self.userDefaults.set(mode.rawValue, forKey: self.modeKey)
        self.userDefaults.set(origin.x, forKey: self.originXKey)
        self.userDefaults.set(origin.y, forKey: self.originYKey)
    }
}
