import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

// Add extension for named store
extension ManagedSettingsStore.Name {
    static let social = Self("social")
}

class DeviceActivityManager {
    static let shared = DeviceActivityManager()
    
    private let center = AuthorizationCenter.shared
    private let userDefaults = UserDefaults.standard
    private let firstPickupKey = "firstPickupTimeKey"
    private let longestActivityKey = "longestActivityKey"
    private let deviceActivityCenter = DeviceActivityCenter()
    
    // Request authorization for monitoring app usage
    func requestAuthorization() async -> Bool {
        do {
            try await center.requestAuthorization(for: .individual)
            return true
        } catch {
            print("Failed to request authorization: \(error.localizedDescription)")
            return false
        }
    }
    
    // In the main app, you cannot fetch historical device activity data.
    // This must be done in the Device Activity Report Extension.
    func fetchActivityData() async -> [AppUsageData] {
        // Not available in the main app. Only available in the extension.
        return []
    }
    
    func getFirstPickupTime() -> Date? {
        return userDefaults.object(forKey: firstPickupKey) as? Date
    }
    
    func getLongestActivitySession() -> DateInterval? {
        guard let start = userDefaults.object(forKey: "\(longestActivityKey)_start") as? Date,
              let end = userDefaults.object(forKey: "\(longestActivityKey)_end") as? Date else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }
    
    func resetActivityData() {
        userDefaults.removeObject(forKey: firstPickupKey)
        userDefaults.removeObject(forKey: "\(longestActivityKey)_start")
        userDefaults.removeObject(forKey: "\(longestActivityKey)_end")
    }
    
    // Schedules the DeviceActivity report extension to run daily
    func scheduleUsageTracking() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let center = DeviceActivityCenter()
        do {
            try center.startMonitoring(DeviceActivityName("daily"), during: schedule)
            print("[DeviceActivityManager] DeviceActivity monitoring scheduled for daily.")
        } catch {
            print("[DeviceActivityManager] Failed to schedule DeviceActivity monitoring: \(error)")
        }
    }

    // Schedules a short test interval for debugging extension triggering (minimum allowed by iOS is ~15 minutes)
    func scheduleTestUsageTracking() {
        let now = Date()
        let inFifteenMinutes = now.addingTimeInterval(15 * 60)
        let start = Calendar.current.dateComponents([.hour, .minute], from: now)
        let end = Calendar.current.dateComponents([.hour, .minute], from: inFifteenMinutes)
        let schedule = DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: end,
            repeats: false
        )
        let center = DeviceActivityCenter()
        do {
            try center.startMonitoring(DeviceActivityName("test"), during: schedule)
            print("[DeviceActivityManager] DeviceActivity monitoring scheduled for 15-minute test interval.")
        } catch {
            print("[DeviceActivityManager] Failed to schedule test DeviceActivity monitoring: \(error)")
        }
    }

    func printExtensionDebugLog() {
        if let logURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.ericqin.shift")?.appendingPathComponent("debug.txt"),
           let logContents = try? String(contentsOf: logURL) {
            print("[Extension Debug Log]\n" + logContents)
        } else {
            print("[Extension Debug Log] No log file found.")
        }
    }
}

class ShiftDeviceActivityMonitor: DeviceActivityMonitor {
    // Use a named store for social restrictions (Apple methodology)
    let socialStore = ManagedSettingsStore(named: .social)
    // Provide a socialCategoryToken (example: first discouraged category)
    var socialCategoryToken: ActivityCategoryToken? {
        MyModel.shared.selectionToDiscourage.categoryTokens.first
    }
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("[MonitorExtension] intervalDidStart for \(activity.rawValue)")
        // Clear all restrictions at the start of the interval
        socialStore.clearAllSettings()
    }
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("[MonitorExtension] intervalDidEnd for \(activity.rawValue)")
        // Apply social restrictions at the end of the interval
        // Example: shield a social category (replace with your actual token)
        if let socialCategory = socialCategoryToken {
            socialStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific([socialCategory])
            socialStore.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy.specific([socialCategory])
        }
    }
}
