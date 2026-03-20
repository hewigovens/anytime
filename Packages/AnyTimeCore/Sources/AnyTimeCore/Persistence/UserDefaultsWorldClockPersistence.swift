import Foundation

public struct UserDefaultsWorldClockPersistence: WorldClockPersisting {
    public let userDefaults: UserDefaults
    public let key: String

    public init(
        userDefaults: UserDefaults = .standard,
        key: String = "AnyTime.Configuration.v2"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func loadConfiguration() -> WorldClockConfiguration? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(WorldClockConfiguration.self, from: data)
    }

    public func saveConfiguration(_ configuration: WorldClockConfiguration) {
        guard let data = try? JSONEncoder().encode(configuration) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }
}
