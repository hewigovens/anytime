import Foundation

enum AppStoreScreenshotScenario: String {
    case home
    case referenceTime = "reference-time"
    case search
    case settings

    private static let environment = ProcessInfo.processInfo.environment

    static var current: AppStoreScreenshotScenario? {
        guard let rawValue = environment["ANYTIME_SCREENSHOT_SCENARIO"] else {
            return nil
        }

        return AppStoreScreenshotScenario(rawValue: rawValue)
    }

    static var searchText: String? {
        environment["ANYTIME_SCREENSHOT_SEARCH_TEXT"]
    }

    static var referenceDate: Date? {
        guard let rawValue = environment["ANYTIME_SCREENSHOT_REFERENCE_DATE"] else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: rawValue)
    }
}
