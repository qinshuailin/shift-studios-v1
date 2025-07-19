import Foundation
import Combine
import ActivityKit

class StatsManager: ObservableObject {
    static let shared = StatsManager()
    
    // Published properties for SwiftUI
    @Published var totalFocusTime: Int = 0
    @Published var currentStreak: Int = 0
    @Published var appUsageData: [AppUsageData] = []
    @Published var weeklyData: [Int] = [0, 0, 0, 0, 0, 0, 0]
    @Published var categoryUsageData: [CategoryUsageData] = []
    @Published var pickupsData: [(String, Double)] = []
    @Published var hourlyUsageData: [(String, Double)] = []
    @Published var firstPickupTime: Date? = nil
    @Published var longestSession: DateInterval? = nil
    @Published var isFocusModeActive: Bool = false
    @Published var focusScore: Double = 0.0
    @Published var focusModeStartTime: Date? = nil
    @Published var totalFocusModeTime: TimeInterval = 0
    @Published var lastFocusSession: FocusSession? = nil
    @Published var lastUpdated: Date? = nil
    
    private let userDefaults = UserDefaults.standard
    private let focusSessionsKey = "focusSessionsKey"
    private let dailyMinutesKey = "dailyMinutesKey"
    private let weeklyMinutesKey = "weeklyMinutesKey"
    private let currentStreakKey = "currentStreakKey"
    private let lastFocusDayKey = "lastFocusDayKey"
    private let hourlyUsageKey = "hourlyUsageKey"
    private let focusModeActiveKey = "focusModeActiveKey"
    private let focusScoreKey = "focusScoreKey"
    private let appGroupID = "group.com.ericqin.shift" // Use your actual App Group ID
    
    private var refreshTimer: Timer?
    private var liveActivityTimer: Timer?
    private let appGroupUsageKey = "AppUsageData" // Ensure this matches the extension's key
    
    private init() {
        loadData()
        startAutoRefresh()
    }
    
    func loadData() {
        // Use selection from MyModel
        let selection = MyModel.shared.selectionToDiscourage
        print("[StatsManager] Current selection to discourage: \(selection)")
        // Load real data from App Group
        loadAppGroupUsageData()
        totalFocusTime = getDailyFocusMinutes()
        currentStreak = getCurrentStreak()
        weeklyData = getWeeklyFocusMinutes()
        categoryUsageData = getUsageByCategory()
        pickupsData = getAppPickups()
        hourlyUsageData = getHourlyUsageData()
        firstPickupTime = getFirstPickupTime()
        longestSession = getLongestActivitySession()
        isFocusModeActive = userDefaults.bool(forKey: focusModeActiveKey)
        focusScore = userDefaults.double(forKey: focusScoreKey)
        if focusScore == 0 {
            focusScore = calculateFocusScore()
            userDefaults.set(focusScore, forKey: focusScoreKey)
        }
        lastUpdated = Date()
        // Debug: Print usage data from App Group
        printAppGroupUsageData()
    }

    private func loadAppGroupUsageData() {
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = defaults?.data(forKey: "usageData"),
           let usageDict = try? JSONDecoder().decode([String: TimeInterval].self, from: data) {
            print("[Main App] Read usage data from app group: \(usageDict)")
            // Map [String: TimeInterval] to [AppUsageData]
            self.appUsageData = usageDict.map { (name, duration) in
                AppUsageData(bundleID: nil, name: name, duration: duration)
            }.sorted { $0.duration > $1.duration }
        } else {
            print("[Main App] No usage data found or failed to decode.")
            self.appUsageData = []
        }
        lastUpdated = Date()
    }
    
    // MARK: - Session Tracking
    
    func toggleFocusMode() {
        if isFocusModeActive {
            endFocusSession()
        } else {
            startFocusSession()
        }
    }
    
    func startFocusSession() {
        let session = FocusSession(startTime: Date())
        saveFocusSession(session)
        userDefaults.set(true, forKey: focusModeActiveKey)
        isFocusModeActive = true
        focusModeStartTime = session.startTime
        // Start Live Activity
        let goalMinutes = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        FocusLiveActivityManager.shared.start(goalMinutes: goalMinutes > 0 ? goalMinutes : 60)
        // Start timer to update Live Activity every second
        liveActivityTimer?.invalidate()
        liveActivityTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateLiveActivityTimer()
        }
        NotificationCenter.default.post(name: NSNotification.Name(Constants.Notifications.focusModeEnabled), object: nil)
    }
    
    func endFocusSession() {
        guard var sessions = getFocusSessions(), !sessions.isEmpty else { return }
        
        // Update the last session with end time
        var lastSession = sessions.removeLast()
        lastSession.endTime = Date()
        
        // Calculate duration and update stats
        if let duration = lastSession.durationInMinutes {
            updateDailyMinutes(adding: duration)
            updateWeeklyMinutes(adding: duration)
            updateHourlyUsage(adding: duration, at: lastSession.startTime)
            totalFocusModeTime += Double(duration) * 60
        }
        
        // Save updated session
        sessions.append(lastSession)
        saveFocusSessions(sessions)
        userDefaults.set(false, forKey: focusModeActiveKey)
        isFocusModeActive = false
        self.lastFocusSession = lastSession
        focusModeStartTime = nil
        
        // End Live Activity
        let elapsed = lastSession.endTime?.timeIntervalSince(lastSession.startTime) ?? 0
        FocusLiveActivityManager.shared.end(finalElapsedSeconds: Int(elapsed))
        liveActivityTimer?.invalidate()
        liveActivityTimer = nil
        
        // Update focus score
        focusScore = calculateFocusScore()
        userDefaults.set(focusScore, forKey: focusScoreKey)
        
        // Reload data to update published properties
        loadData()
        
        NotificationCenter.default.post(name: NSNotification.Name(Constants.Notifications.focusModeDisabled), object: nil)
    }
    
    // Calculate focus score based on usage patterns
    func calculateFocusScore() -> Double {
        // Algorithm based on:
        // 1. Daily goal progress
        // 2. Streak length
        // 3. App usage reduction
        let dailyGoal = 400 // Default goal
        let goalProgress = min(Double(totalFocusTime) / Double(dailyGoal), 1.0)
        let streakFactor = min(Double(currentStreak) / 7.0, 1.0) // Max benefit at 7-day streak
        
        // Get weekly comparison
        let thisWeek = weeklyData.reduce(0, +)
        let previousWeek = Double(thisWeek) * 1.07 // Simulating 7% more last week
        let percentChange = (Double(thisWeek) - previousWeek) / previousWeek * 100
        let usageReduction = abs(percentChange) / 100.0 * (percentChange < 0 ? 1.0 : -0.5)
        
        let baseScore = (goalProgress * 5.0) + (streakFactor * 3.0) + (usageReduction * 2.0)
        return min(max(baseScore, 1.0), 10.0) // Ensure between 1.0-10.0
    }
    
    // MARK: - Focus Mode Status
    
    func checkFocusModeActive() -> Bool {
        let active = userDefaults.bool(forKey: focusModeActiveKey)
        isFocusModeActive = active
        return active
    }
    
    // MARK: - Session Data
    
    func getFocusSessions() -> [FocusSession]? {
        guard let data = userDefaults.data(forKey: focusSessionsKey) else { return nil }
        
        do {
            return try JSONDecoder().decode([FocusSession].self, from: data)
        } catch {
            print("Error decoding focus sessions: \(error)")
            return nil
        }
    }
    
    private func saveFocusSession(_ session: FocusSession) {
        var sessions = getFocusSessions() ?? []
        sessions.append(session)
        saveFocusSessions(sessions)
    }
    
    private func saveFocusSessions(_ sessions: [FocusSession]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: focusSessionsKey)
        } catch {
            print("Error encoding focus sessions: \(error)")
        }
    }
    
    // MARK: - Stats Retrieval
    
    func getDailyFocusMinutes() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "\(dailyMinutesKey)_\(today.timeIntervalSince1970)"
        return userDefaults.integer(forKey: key)
    }
    
    func getWeeklyFocusMinutes() -> [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var weeklyData: [Int] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let key = "\(dailyMinutesKey)_\(date.timeIntervalSince1970)"
            let minutes = userDefaults.integer(forKey: key)
            weeklyData.insert(minutes, at: 0)
        }
        
        return weeklyData
    }
    
    func getCurrentStreak() -> Int {
        return userDefaults.integer(forKey: currentStreakKey)
    }
    
    func getMostBlockedApps() -> [AppUsageData] {
        return AppUsageTracker.shared.getBlockedDurations()
            .sorted(by: { $0.duration > $1.duration })
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Enhanced Stats Methods
    
    func getUsageByCategory() -> [CategoryUsageData] {
        let allApps = AppUsageTracker.shared.getBlockedDurations()
        
        // Group apps by category
        var categorizedApps: [String: [AppUsageData]] = [:]
        
        for app in allApps {
            let category = app.category
            if categorizedApps[category] == nil {
                categorizedApps[category] = []
            }
            categorizedApps[category]?.append(app)
        }
        
        // Create category usage data
        return categorizedApps.map { CategoryUsageData(category: $0.key, apps: $0.value) }
            .sorted(by: { $0.totalTime > $1.totalTime })
    }
    
    func getAppPickups() -> [(String, Double)] {
        let allApps = AppUsageTracker.shared.getBlockedDurations()
        
        return allApps.sorted(by: { $0.numberOfPickups > $1.numberOfPickups })
            .prefix(5)
            .map { ($0.name, Double($0.numberOfPickups)) }
    }
    
    func getAppNotifications() -> [(String, Double)] {
        let allApps = AppUsageTracker.shared.getBlockedDurations()
        
        return allApps.sorted(by: { $0.numberOfNotifications > $1.numberOfNotifications })
            .prefix(5)
            .map { ($0.name, Double($0.numberOfNotifications)) }
    }
    
    func getHourlyUsageData() -> [(String, Double)] {
        var hourlyData: [(String, Double)] = []
        
        for hour in 0..<24 {
            let key = "\(hourlyUsageKey)_\(hour)"
            let minutes = userDefaults.double(forKey: key)
            let hourString = String(format: "%d %@", hour % 12 == 0 ? 12 : hour % 12, hour >= 12 ? "PM" : "AM")
            hourlyData.append((hourString, minutes))
        }
        
        return hourlyData
    }
    
    func getFirstPickupTime() -> Date? {
        return DeviceActivityManager.shared.getFirstPickupTime()
    }
    
    func getLongestActivitySession() -> DateInterval? {
        return DeviceActivityManager.shared.getLongestActivitySession()
    }
    
    // MARK: - Private Helpers
    
    private func updateDailyMinutes(adding minutes: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "\(dailyMinutesKey)_\(today.timeIntervalSince1970)"
        let currentMinutes = userDefaults.integer(forKey: key)
        userDefaults.set(currentMinutes + minutes, forKey: key)
        totalFocusTime = currentMinutes + minutes
        
        updateStreak()
    }
    
    private func updateWeeklyMinutes(adding minutes: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        let key = "\(weeklyMinutesKey)_\(weekday)"
        let currentMinutes = userDefaults.integer(forKey: key)
        userDefaults.set(currentMinutes + minutes, forKey: key)
        
        // Update weekly data
        weeklyData = getWeeklyFocusMinutes()
    }
    
    private func updateHourlyUsage(adding minutes: Int, at date: Date) {
        let hour = Calendar.current.component(.hour, from: date)
        let key = "\(hourlyUsageKey)_\(hour)"
        let currentMinutes = userDefaults.double(forKey: key)
        userDefaults.set(currentMinutes + Double(minutes), forKey: key)
        
        // Update hourly data
        hourlyUsageData = getHourlyUsageData()
    }
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayKey = "\(today.timeIntervalSince1970)"
        
        if let lastFocusDay = userDefaults.string(forKey: lastFocusDayKey) {
            if lastFocusDay != todayKey {
                // Check if yesterday
                guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return }
                let yesterdayKey = "\(yesterday.timeIntervalSince1970)"
                
                if lastFocusDay == yesterdayKey {
                    // Increment streak
                    let currentStreakValue = userDefaults.integer(forKey: currentStreakKey)
                    userDefaults.set(currentStreakValue + 1, forKey: currentStreakKey)
                    currentStreak = currentStreakValue + 1
                } else {
                    // Reset streak
                    userDefaults.set(1, forKey: currentStreakKey)
                    currentStreak = 1
                }
                
                userDefaults.set(todayKey, forKey: lastFocusDayKey)
            }
        } else {
            // First day
            userDefaults.set(1, forKey: currentStreakKey)
            userDefaults.set(todayKey, forKey: lastFocusDayKey)
            currentStreak = 1
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.loadAppGroupUsageData()
        }
    }
    
    private func reloadAppGroupUsageData() {
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = defaults?.data(forKey: appGroupUsageKey),
           let usage = try? JSONDecoder().decode([AppUsageData].self, from: data) {
            DispatchQueue.main.async {
                self.appUsageData = usage
            }
        }
    }
    
    // Debug: Read and print per-app usage data from App Group
    func printAppGroupUsageData() {
        if let sharedDefaults = UserDefaults(suiteName: appGroupID),
           let jsonData = sharedDefaults.data(forKey: "usageData"),
           let usageData = try? JSONDecoder().decode([String: TimeInterval].self, from: jsonData) {
            print("[App Group] Usage data:", usageData)
        } else {
            print("[App Group] No usage data found or failed to decode.")
        }
    }
    
    // Helper to update the Live Activity timer
    private func updateLiveActivityTimer() {
        guard let start = focusModeStartTime else { return }
        let elapsed = Int(Date().timeIntervalSince(start))
        FocusLiveActivityManager.shared.update(elapsedSeconds: elapsed)
    }
}

extension StatsManager {
    var timeSavedString: String {
        TimeInterval(totalFocusModeTime).formattedDuration()
    }
    var timeWastedString: String {
        let wasted = appUsageData.reduce(0) { $0 + $1.duration }
        return TimeInterval(wasted).formattedDuration()
    }
    var progressToGoal: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(totalFocusModeTime / Double(dailyGoal * 60), 1.0)
    }
    var mostUsedApps: [AppUsageData] {
        appUsageData.sorted { $0.duration > $1.duration }
    }
}
