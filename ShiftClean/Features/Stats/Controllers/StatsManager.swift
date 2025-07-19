import Foundation
import Combine
import ActivityKit

class StatsManager: ObservableObject {
    static let shared = StatsManager()
    
    // Published properties for SwiftUI
    @Published var totalFocusTime: Int = 0 // Total minutes from completed sessions TODAY
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
    @Published var lastFocusSession: FocusSession? = nil
    @Published var lastUpdated: Date? = nil
    // NEW: Live updating property for total time saved today (includes current session)
    @Published var totalTimeSavedToday: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let focusSessionsKey = "focusSessionsKey"
    private let dailyMinutesKey = "dailyMinutesKey"
    private let weeklyMinutesKey = "weeklyMinutesKey"
    private let currentStreakKey = "currentStreakKey"
    private let lastFocusDayKey = "lastFocusDayKey"
    private let hourlyUsageKey = "hourlyUsageKey"
    private let focusModeActiveKey = "focusModeActiveKey"
    private let focusScoreKey = "focusScoreKey"
    private let appGroupID = "group.com.ericqin.shift"
    
    private var refreshTimer: Timer?
    private var liveActivityTimer: Timer?
    private var liveUpdateTimer: Timer? // NEW: Timer for live updates
    private let appGroupUsageKey = "AppUsageData"
    
    private init() {
        loadData()
        startAutoRefresh()
        startLiveUpdates() // NEW: Start live updating
    }
    
    func loadData() {
        // Load real data from App Group
        loadAppGroupUsageData()
        totalFocusTime = getDailyFocusMinutes()
        updateTotalTimeSavedToday() // NEW: Calculate total time saved today
        currentStreak = getCurrentStreak()
        weeklyData = getWeeklyFocusMinutes()
        categoryUsageData = getUsageByCategory()
        pickupsData = getAppPickups()
        hourlyUsageData = getHourlyUsageData()
        firstPickupTime = getFirstPickupTime()
        longestSession = getLongestActivitySession()
        isFocusModeActive = userDefaults.bool(forKey: focusModeActiveKey)
        
        // Load focus mode start time if active
        if isFocusModeActive {
            if let sessions = getFocusSessions(), let lastSession = sessions.last, lastSession.isActive {
                focusModeStartTime = lastSession.startTime
            }
        }
        
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
    
    // NEW: Calculate total time saved today (completed sessions + current session)
    private func updateTotalTimeSavedToday() {
        var total = totalFocusTime // Completed sessions today
        // Add current session time if focus mode is active
        if isFocusModeActive, let start = focusModeStartTime {
            let currentSessionMinutes = Int(Date().timeIntervalSince(start) / 60)
            total += currentSessionMinutes
        }
        totalTimeSavedToday = total
    }
    
    // NEW: Start live updates every second when focus mode is active
    private func startLiveUpdates() {
        liveUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isFocusModeActive {
                self.updateTotalTimeSavedToday()
            }
        }
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
        // Prevent starting if already active
        guard !isFocusModeActive else {
            print("[StatsManager] Focus session already active, ignoring duplicate start")
            return
        }
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
        guard isFocusModeActive else { return } // Prevent duplicate endings
        // Update the last session with end time
        var lastSession = sessions.removeLast()
        lastSession.endTime = Date()
        // Calculate duration in minutes
        let durationMinutes: Int
        if let duration = lastSession.durationInMinutes {
            durationMinutes = duration
        } else {
            durationMinutes = 0
        }
        // FIXED: Only add to completed session time, don't double count
        if durationMinutes > 0 {
            updateDailyMinutes(adding: durationMinutes)
            updateWeeklyMinutes(adding: durationMinutes)
            updateHourlyUsage(adding: durationMinutes, at: lastSession.startTime)
        }
        // Save updated session
        sessions.append(lastSession)
        saveFocusSessions(sessions)
        userDefaults.set(false, forKey: focusModeActiveKey)
        isFocusModeActive = false
        self.lastFocusSession = lastSession
        focusModeStartTime = nil
        // End Live Activity
        let elapsedSeconds = lastSession.endTime?.timeIntervalSince(lastSession.startTime) ?? 0
        FocusLiveActivityManager.shared.end(finalElapsedSeconds: Int(elapsedSeconds))
        liveActivityTimer?.invalidate()
        liveActivityTimer = nil
        // Update focus score
        focusScore = calculateFocusScore()
        userDefaults.set(focusScore, forKey: focusScoreKey)
        // Update total time saved today to reflect completed session
        updateTotalTimeSavedToday()
        NotificationCenter.default.post(name: NSNotification.Name(Constants.Notifications.focusModeDisabled), object: nil)
    }
    
    // Calculate focus score based on usage patterns
    func calculateFocusScore() -> Double {
        // Algorithm based on:
        // 1. Daily goal progress  
        // 2. Streak length
        // 3. App usage reduction
        let dailyGoal = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        let goalMinutes = dailyGoal > 0 ? dailyGoal : 120
        let goalProgress = min(Double(totalTimeSavedToday) / Double(goalMinutes), 1.0)
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
        totalFocusTime = currentMinutes + minutes // Update completed sessions time
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
        let dailyGoal = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        let goalMinutes = dailyGoal > 0 ? dailyGoal : 120
        if totalTimeSavedToday >= goalMinutes {
            // User met the goal today
            if let lastFocusDay = userDefaults.string(forKey: lastFocusDayKey) {
                if lastFocusDay != todayKey {
                    // Check if yesterday was also a streak day
                    guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return }
                    let yesterdayKey = "\(yesterday.timeIntervalSince1970)"
                    if lastFocusDay == yesterdayKey {
                        // Continue streak
                        let currentStreakValue = userDefaults.integer(forKey: currentStreakKey)
                        userDefaults.set(currentStreakValue + 1, forKey: currentStreakKey)
                        currentStreak = currentStreakValue + 1
                    } else {
                        // Start new streak
                        userDefaults.set(1, forKey: currentStreakKey)
                        currentStreak = 1
                    }
                    userDefaults.set(todayKey, forKey: lastFocusDayKey)
                }
            } else {
                // First streak day
                userDefaults.set(1, forKey: currentStreakKey)
                userDefaults.set(todayKey, forKey: lastFocusDayKey)
                currentStreak = 1
            }
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.loadAppGroupUsageData()
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
    
    deinit {
        liveUpdateTimer?.invalidate()
        refreshTimer?.invalidate()
        liveActivityTimer?.invalidate()
    }
}

// MARK: - Extensions
extension StatsManager {
    var timeSavedString: String {
        return TimeInterval(totalTimeSavedToday * 60).formattedDuration()
    }
    
    var timeWastedString: String {
        let wasted = appUsageData.reduce(0) { $0 + $1.duration }
        return TimeInterval(wasted).formattedDuration()
    }
    
    var progressToGoal: Double {
        let dailyGoal = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        let goalMinutes = dailyGoal > 0 ? dailyGoal : 120
        return min(Double(totalTimeSavedToday) / Double(goalMinutes), 1.0)
    }
    
    var mostUsedApps: [AppUsageData] {
        appUsageData.sorted { $0.duration > $1.duration }
    }
    
    // Add a property for daily goal that reads from UserDefaults
    var dailyGoal: Int {
        get {
            let goal = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
            return goal > 0 ? goal : 120 // Default to 120 minutes if not set
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "dailyGoalMinutes")
        }
    }
    
    // Add a method to update daily goal
    func updateDailyGoal(_ newGoal: Int) {
        dailyGoal = newGoal
    }
}
