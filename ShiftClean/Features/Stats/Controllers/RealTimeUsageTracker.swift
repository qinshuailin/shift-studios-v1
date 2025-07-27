import Foundation
import UIKit

class RealTimeUsageTracker: ObservableObject {
    static let shared = RealTimeUsageTracker()
    private var timer: Timer?
    private var usageData: [String: TimeInterval] = [:]
    private var currentApp: String? // Set this to the bundle ID or name of the app being tracked
    private var lastActiveDate: Date?

    private let appGroupID = "group.com.ericqin.shift"

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func startTracking(appName: String) {
        currentApp = appName
        lastActiveDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.incrementUsage()
        }
    }

    func stopTracking() {
        timer?.invalidate()
        timer = nil
        currentApp = nil
        lastActiveDate = nil
    }

    private func incrementUsage() {
        guard let app = currentApp else { return }
        // Store in seconds (as TimeInterval expects), increment by 1 second
        usageData[app, default: 0] += 1.0  // 1.0 second as TimeInterval
        writeUsageDataToAppGroup()
    }

    @objc private func appDidEnterBackground() {
        stopTracking()
    }

    @objc private func appDidBecomeActive() {
        if let app = currentApp {
            startTracking(appName: app)
        }
    }

    private func writeUsageDataToAppGroup() {
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            if let jsonData = try? JSONEncoder().encode(usageData) {
                sharedDefaults.set(jsonData, forKey: "usageData")
            }
        }
    }
} 