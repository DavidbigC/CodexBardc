import AppKit

enum HUDDisplayMode: String {
    case collapsed
    case expanded
    case tucked
}

struct HUDStoredState {
    var mode: HUDDisplayMode
    var origin: CGPoint?
    var size: CGSize?
}

@MainActor
final class HUDPersistence {
    static let shared = HUDPersistence()

    private let userDefaults: UserDefaults
    private let modeKey = "hud.mode"
    private let originXKey = "hud.origin.x"
    private let originYKey = "hud.origin.y"
    private let widthKey = "hud.size.width"
    private let heightKey = "hud.size.height"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadState() -> HUDStoredState {
        let rawMode = self.userDefaults.string(forKey: self.modeKey)
        let storedMode = HUDDisplayMode(rawValue: rawMode ?? "") ?? .collapsed
        let mode: HUDDisplayMode = storedMode == .expanded ? .collapsed : storedMode
        let hasOrigin = self.userDefaults.object(forKey: self.originXKey) != nil &&
            self.userDefaults.object(forKey: self.originYKey) != nil
        let origin: CGPoint? = hasOrigin
            ? CGPoint(
                x: self.userDefaults.double(forKey: self.originXKey),
                y: self.userDefaults.double(forKey: self.originYKey))
            : nil
        let hasSize = self.userDefaults.object(forKey: self.widthKey) != nil &&
            self.userDefaults.object(forKey: self.heightKey) != nil
        let size: CGSize? = hasSize
            ? CGSize(
                width: self.userDefaults.double(forKey: self.widthKey),
                height: self.userDefaults.double(forKey: self.heightKey))
            : nil
        return HUDStoredState(mode: mode, origin: origin, size: size)
    }

    func save(mode: HUDDisplayMode, origin: CGPoint, size: CGSize?) {
        self.userDefaults.set(mode.rawValue, forKey: self.modeKey)
        self.userDefaults.set(origin.x, forKey: self.originXKey)
        self.userDefaults.set(origin.y, forKey: self.originYKey)
        if let size {
            self.userDefaults.set(size.width, forKey: self.widthKey)
            self.userDefaults.set(size.height, forKey: self.heightKey)
        } else {
            self.userDefaults.removeObject(forKey: self.widthKey)
            self.userDefaults.removeObject(forKey: self.heightKey)
        }
    }
}
