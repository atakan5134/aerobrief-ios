import Foundation
import Combine

/// Persists user-configurable settings to UserDefaults.
/// Sensitive values (the AVWX API key) are stored in the Keychain instead —
/// UserDefaults backs onto a plist that's included in unencrypted device
/// backups, which isn't appropriate for API credentials.
final class AppSettings: ObservableObject {
    // MARK: Backend URL
    @Published var backendURLString: String {
        didSet { UserDefaults.standard.set(backendURLString, forKey: Self.Keys.backendURL) }
    }

    // MARK: Default aircraft type (used when auto-detect fails)
    @Published var defaultAircraftType: AircraftType {
        didSet { UserDefaults.standard.set(defaultAircraftType.rawValue, forKey: Self.Keys.defaultAircraft) }
    }

    // MARK: AVWX API key for real D-ATIS data (Keychain-backed, see above)
    @Published var avwxApiKey: String {
        didSet { KeychainService.set(avwxApiKey, forKey: Self.Keys.avwxApiKey) }
    }

    // MARK: Wind limits (kt) — operator configurable
    @Published var maxHeadwind: Int {
        didSet { UserDefaults.standard.set(maxHeadwind, forKey: Self.Keys.maxHeadwind) }
    }
    @Published var maxCrosswind: Int {
        didSet { UserDefaults.standard.set(maxCrosswind, forKey: Self.Keys.maxCrosswind) }
    }
    @Published var maxTailwind: Int {
        didSet { UserDefaults.standard.set(maxTailwind, forKey: Self.Keys.maxTailwind) }
    }

    private enum Keys {
        static let backendURL      = "aerobrief.backendURL"
        static let defaultAircraft = "aerobrief.defaultAircraft"
        static let avwxApiKey      = "aerobrief.avwxApiKey"
        static let maxHeadwind     = "aerobrief.maxHeadwind"
        static let maxCrosswind    = "aerobrief.maxCrosswind"
        static let maxTailwind     = "aerobrief.maxTailwind"
    }

    init() {
        let ud = UserDefaults.standard

        self.backendURLString = ud.string(forKey: Keys.backendURL) ?? "https://aerobrief-backend-production.up.railway.app"

        let storedAircraft = ud.string(forKey: Keys.defaultAircraft).flatMap { AircraftType(rawValue: $0) }
        self.defaultAircraftType = storedAircraft ?? .a320

        if let keychainValue = KeychainService.get(forKey: Keys.avwxApiKey) {
            self.avwxApiKey = keychainValue
        } else if let legacyValue = ud.string(forKey: Keys.avwxApiKey), !legacyValue.isEmpty {
            // One-time migration: earlier builds stored this in UserDefaults.
            // Move it to the Keychain and scrub the plaintext copy.
            self.avwxApiKey = legacyValue
            KeychainService.set(legacyValue, forKey: Keys.avwxApiKey)
            ud.removeObject(forKey: Keys.avwxApiKey)
        } else {
            self.avwxApiKey = ""
        }

        self.maxHeadwind  = ud.object(forKey: Keys.maxHeadwind)  != nil ? ud.integer(forKey: Keys.maxHeadwind)  : 50
        self.maxCrosswind = ud.object(forKey: Keys.maxCrosswind) != nil ? ud.integer(forKey: Keys.maxCrosswind) : 25
        self.maxTailwind  = ud.object(forKey: Keys.maxTailwind)  != nil ? ud.integer(forKey: Keys.maxTailwind)  : 15
    }

    var backendURL: URL {
        URL(string: backendURLString) ?? URL(string: "https://aerobrief-backend-production.up.railway.app")!
    }

    func makeBriefingService() -> BriefingServicing {
        BriefingService(client: APIClient(baseURL: backendURL))
    }
}
