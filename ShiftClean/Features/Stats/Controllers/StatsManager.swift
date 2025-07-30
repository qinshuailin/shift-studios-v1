import Foundation
import Combine
import ActivityKit
import UIKit

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
    private let focusModeActiveKey = "focusModeActive"
    private let focusScoreKey = "focusScoreKey"
    private let appGroupID = "group.com.ericqin.shift"
    
    private var refreshTimer: Timer?
    private var liveActivityTimer: Timer?
    private var liveUpdateTimer: Timer? // NEW: Timer for live updates
    private let appGroupUsageKey = "AppUsageData"
    
    // CRITICAL: Force reset all focus session state
    private func forceResetFocusState() {
        print("[StatsManager] Force resetting focus state")
        
        // Stop all timers
        liveActivityTimer?.invalidate()
        liveActivityTimer = nil
        
        // Clear all state
        isFocusModeActive = false
        focusModeStartTime = nil
        
        // Clear UserDefaults
        userDefaults.set(false, forKey: focusModeActiveKey)
        userDefaults.removeObject(forKey: "focusModeStartTime")
        
        // Sync with AppBlockingService (but don't call StatsManager methods to avoid recursion)
        userDefaults.set(false, forKey: "focusModeActive")
        
        print("[StatsManager] Focus state reset complete")
    }
    
    // MARK: - Initialization
    init() {
        print("[StatsManager] Initializing")
        
        // BULLETPROOF: Add background/foreground observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Load focus mode state from UserDefaults
        let savedFocusState = userDefaults.bool(forKey: focusModeActiveKey)
        print("[StatsManager] Loaded focus state: \(savedFocusState)")
        
        // Check if there's a valid active session
        if savedFocusState {
            // Verify we actually have a start time
            if let startTime = userDefaults.object(forKey: "focusModeStartTime") as? Date {
                // Check if the session is recent (within 24 hours)
                let timeSinceStart = Date().timeIntervalSince(startTime)
                if timeSinceStart < 24 * 60 * 60 { // 24 hours
                    print("[StatsManager] Restoring session from \(startTime)")
                    isFocusModeActive = true
                    focusModeStartTime = startTime
                    startLiveActivityTimer()
                } else {
                    print("[StatsManager] Session expired (\(timeSinceStart/3600)h), clearing")
                    // Clear stale state
                    userDefaults.set(false, forKey: focusModeActiveKey)
                    userDefaults.removeObject(forKey: "focusModeStartTime")
                    isFocusModeActive = false
                    focusModeStartTime = nil
                }
            } else {
                print("[StatsManager] No start time found, clearing state")
                // Clear inconsistent state
                userDefaults.set(false, forKey: focusModeActiveKey)
                isFocusModeActive = false
                focusModeStartTime = nil
            }
        } else {
            print("[StatsManager] No active session found")
            isFocusModeActive = false
            focusModeStartTime = nil
        }
        
        // CRITICAL: Synchronize with AppBlockingService state
        let appBlockingActive = AppBlockingService.shared.isFocusModeActive()
        if isFocusModeActive != appBlockingActive {
                    print("[StatsManager] State mismatch: Stats=\(isFocusModeActive), Blocking=\(appBlockingActive)")
        print("[StatsManager] Syncing to blocking state: \(appBlockingActive)")
            isFocusModeActive = appBlockingActive
            if !appBlockingActive {
                focusModeStartTime = nil
                userDefaults.set(false, forKey: focusModeActiveKey)
                userDefaults.removeObject(forKey: "focusModeStartTime")
            }
        }
        
        // CRITICAL: Additional validation - if isFocusModeActive but no focusModeStartTime, reset everything
        if isFocusModeActive && focusModeStartTime == nil {
                    print("[StatsManager] Invalid state: active but no start time")
        print("[StatsManager] Force resetting state")
            forceResetFocusState()
        }
        
        print("[StatsManager] Init complete: active=\(isFocusModeActive)")
        
        // Continue with normal initialization
        loadData()
        startAutoRefresh()
        startLiveUpdates() // Start live updating
        updateTotalTimeSavedToday()
        
        // Force UI refresh after state restoration to ensure button text is correct
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func loadData() {
        // Load real data from App Group
        loadAppGroupUsageData()
        totalFocusTime = getDailyFocusMinutes()
        print("[StatsManager] Loaded totalFocusTime: \(totalFocusTime) min")
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
    
    // Make this public so it can be called from outside
    func updateTotalTimeSavedToday() {
        var total = totalFocusTime // Completed sessions today
        print("[StatsManager] Focus time: \(totalFocusTime) min")
        
        // Add current session time if focus mode is active
        if isFocusModeActive, let start = focusModeStartTime {
            let sessionSeconds = Date().timeIntervalSince(start)
            let currentSessionMinutes = Int(sessionSeconds / 60)
            print("[StatsManager] Current session: \(currentSessionMinutes) min")
            
            // Remove any cap or limit here
            total += currentSessionMinutes
            print("[StatsManager] Live update: total=\(total)min (\(totalFocusTime)+\(currentSessionMinutes))")
        } else {
            print("[StatsManager] Live update: total=\(total)min (no active session)")
        }
        
        print("[StatsManager] Final total: \(total) min")
        
        // Only update if the value has actually changed to avoid unnecessary UI updates
        if totalTimeSavedToday != total {
            print("[StatsManager] Updated totalTimeSaved: \(totalTimeSavedToday) -> \(total)")
            DispatchQueue.main.async {
                self.totalTimeSavedToday = total
                // Post notification for UI updates
                NotificationCenter.default.post(
                    name: NSNotification.Name("StatsUpdated"),
                    object: nil
                )
            }
        }
    }
    
    // This timer updates the main app UI every MINUTE
    private func startLiveUpdates() {
        liveUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isFocusModeActive {
                self.updateTotalTimeSavedToday()
                print("[StatsManager] Live update: totalTimeSaved = \(self.totalTimeSavedToday)")
            }
        }
        // Add to main run loop to survive background transitions
        if let timer = liveUpdateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // MARK: - Session Tracking
    
    func toggleFocusMode() {
        // Delegate to AppBlockingService which handles notifications properly
        AppBlockingService.shared.toggleFocusMode()
    }
    
    func startFocusSession() {
        print("[StatsManager] Starting focus session")
        print("[StatsManager] Current state: active=\(isFocusModeActive), start=\(focusModeStartTime?.description ?? "nil")")
        
        // Force reset if in invalid state
        if isFocusModeActive && focusModeStartTime == nil {
            print("[StatsManager] Invalid state detected, resetting")
            forceResetFocusState()
        }
        
        guard !isFocusModeActive else {
            print("[StatsManager] Session already active, ignoring start")
            return
        }
        
        let now = Date()
        focusModeStartTime = now
        isFocusModeActive = true
        
        // CRITICAL: Create and save a FocusSession object
        let newSession = FocusSession(startTime: now)
        saveFocusSession(newSession)
        print("[StatsManager] Created session: \(newSession.id)")
        
        // Persist state
        userDefaults.set(true, forKey: focusModeActiveKey)
        userDefaults.set(now, forKey: "focusModeStartTime")
        
        print("[StatsManager] Session started at: \(now)")
        
        // Start Live Activity with enhanced haptic feedback
        let goalMinutes = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        let goal = goalMinutes > 0 ? goalMinutes : 120
        FocusLiveActivityManager.shared.start(goalMinutes: goal)
        Constants.Haptics.liveActivityStart()
        print("[StatsManager] Started Live Activity: \(goal) min goal")
        
        // Start live activity timer
        startLiveActivityTimer()
        
        // Start live update timer for real-time stats display
        startLiveUpdateTimer()
        
        print("[StatsManager] Start session complete")
        
        NotificationCenter.default.post(name: NSNotification.Name(Constants.Notifications.focusModeEnabled), object: nil)
    }
    
    func endFocusSession() {
        print("[StatsManager] Ending focus session")
        print("[StatsManager] Current active state: \(isFocusModeActive)")
        
        guard isFocusModeActive else { 
            print("[StatsManager] Not active, nothing to end")
            return 
        } // Prevent duplicate endings
        
        guard var sessions = getFocusSessions(), !sessions.isEmpty else { 
            print("[StatsManager] No sessions to end")
            return 
        }
        
        // Stop usage tracking
        RealTimeUsageTracker.shared.stopTracking()
        print("[StatsManager] Stopped usage tracking")
        
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
        
        print("[StatsManager] Session duration: \(durationMinutes) min")
        print("[StatsManager] Current totalFocusTime: \(totalFocusTime) min")
        
        // CRITICAL FIX: Only persist to UserDefaults, don't add to totalFocusTime again
        // The session time was already included in totalTimeSavedToday during the active session
        if durationMinutes > 0 {
            let today = Calendar.current.startOfDay(for: Date())
            let key = "\(dailyMinutesKey)_\(today.timeIntervalSince1970)"
            let currentMinutes = userDefaults.integer(forKey: key)
            userDefaults.set(currentMinutes + durationMinutes, forKey: key)
            print("[StatsManager] Persisted \(durationMinutes) min. Total: \(currentMinutes + durationMinutes)")
        }
        
        sessions.append(lastSession)
        saveFocusSessions(sessions)
        
        // CRITICAL: Clear all state properly
        userDefaults.set(false, forKey: focusModeActiveKey)
        userDefaults.removeObject(forKey: "focusModeStartTime") // Remove saved start time
        isFocusModeActive = false
        focusModeStartTime = nil
        
        // Stop live activity timer
        liveActivityTimer?.invalidate()
        liveActivityTimer = nil
        
        // End Live Activity
        let elapsedSeconds = lastSession.endTime?.timeIntervalSince(lastSession.startTime) ?? 0
        let finalElapsedSeconds = Int(elapsedSeconds)
        FocusLiveActivityManager.shared.end(finalElapsedSeconds: finalElapsedSeconds)
        Constants.Haptics.liveActivityComplete()
        print("[StatsManager] Ended Live Activity: \(finalElapsedSeconds)s")
        
        // CRITICAL: Reload totalFocusTime from UserDefaults and update display
        totalFocusTime = getDailyFocusMinutes()
        print("[StatsManager] Reloaded totalFocusTime: \(totalFocusTime) min")
        updateTotalTimeSavedToday()
        
        print("[StatsManager] End session complete")
        
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
    
    // Make sure this method is robust
    private func updateLiveActivityTimer() {
        guard isFocusModeActive, let start = focusModeStartTime else {
            print("[StatsManager] Live activity timer called but not active")
            liveActivityTimer?.invalidate()
            liveActivityTimer = nil
            return
        }
        
        let elapsed = Int(Date().timeIntervalSince(start))
        
        // Milestone haptic feedback every 5 minutes (300 seconds)
        if elapsed > 0 && elapsed % 300 == 0 {
            Constants.Haptics.liveActivityMilestone()
            print("[StatsManager] 5-minute milestone: \(elapsed/60) min")
        }
        
        FocusLiveActivityManager.shared.update(elapsedSeconds: elapsed)
        lastTimerHeartbeat = Date() // Update heartbeat
    }
    
    // Call this on app launch/foreground to sync Live Activity with actual elapsed time
    func syncLiveActivityIfNeeded() {
        if isFocusModeActive, let start = focusModeStartTime {
            let elapsed = Int(Date().timeIntervalSince(start))
            FocusLiveActivityManager.shared.update(elapsedSeconds: elapsed)
        }
    }
    
    // MARK: - Live Activity Timer Management - BULLETPROOF PUBLIC ACCESS
    func startLiveActivityTimer() {
        print("[StatsManager] Starting live activity timer")
        // Stop any existing timer
        liveActivityTimer?.invalidate()
        
        // Start timer to update Live Activity every 1 SECOND for real-time updates
        liveActivityTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                print("[StatsManager] Self deallocated, invalidating timer")
                timer.invalidate()
                return
            }
            
            // BULLETPROOF: Double-check timer is still valid
            if !timer.isValid {
                print("[StatsManager] Timer invalid, restarting")
                self.startLiveActivityTimer()
                return
            }
            
            self.updateLiveActivityTimer()
        }
        
        // CRITICAL: Add to main run loop with ALL modes to survive everything
        if let timer = liveActivityTimer {
            RunLoop.main.add(timer, forMode: .common)
            RunLoop.main.add(timer, forMode: .default)
            RunLoop.main.add(timer, forMode: .tracking)
        }
        
        print("[StatsManager] Live Activity timer started (1s intervals)")
        
        // ADDITIONAL SAFETY: Schedule a backup timer to restart this timer if it dies
        scheduleTimerWatchdog()
        
        NotificationCenter.default.post(name: NSNotification.Name("LiveActivityTimerStarted"), object: nil)
    }
    
    // BULLETPROOF: Watchdog timer to restart the main timer if it dies
    private var watchdogTimer: Timer?
    private var lastTimerHeartbeat: Date = Date()
    
    private func scheduleTimerWatchdog() {
        watchdogTimer?.invalidate()
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Check if main timer is still alive by checking heartbeat
            let timeSinceLastHeartbeat = Date().timeIntervalSince(self.lastTimerHeartbeat)
            if timeSinceLastHeartbeat > 3 { // If no heartbeat for 3 seconds
                print("[StatsManager] Timer died, restarting")
                self.startLiveActivityTimer()
            }
        }
        
        if let watchdog = watchdogTimer {
            RunLoop.main.add(watchdog, forMode: .common)
        }
    }
    
    private func startLiveUpdateTimer() {
        print("[StatsManager] Starting live update timer")
        // Stop any existing timer
        liveUpdateTimer?.invalidate()
        
        // Start timer to update UI every 60 seconds for live stats display
        liveUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTotalTimeSavedToday()
        }
        
        // Add to main run loop to keep running in background
        if let timer = liveUpdateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        print("[StatsManager] Live update timer started (60s intervals)")
    }
    
    deinit {
        liveUpdateTimer?.invalidate()
        refreshTimer?.invalidate()
        liveActivityTimer?.invalidate()
        watchdogTimer?.invalidate()
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
    }
    
    // BULLETPROOF: Restart timers when app goes to background
    @objc private func appDidEnterBackground() {
        print("[StatsManager] App entering background")
        
        if isFocusModeActive {
            // Update Live Activity immediately before going to background
            if let start = focusModeStartTime {
                let elapsed = Int(Date().timeIntervalSince(start))
                FocusLiveActivityManager.shared.update(elapsedSeconds: elapsed)
                print("[StatsManager] Updated Live Activity to \(elapsed)s before background")
            }
        }
    }
    
    // BULLETPROOF: Aggressively restart everything when app comes to foreground
    @objc private func appWillEnterForeground() {
        print("[StatsManager] App entering foreground, restarting timers")
        
        if isFocusModeActive {
            print("[StatsManager] Focus mode active, restarting")
            
            // Immediately restart Live Activity timer
            startLiveActivityTimer()
            
            // Sync Live Activity with current time
            if let start = focusModeStartTime {
                let elapsed = Int(Date().timeIntervalSince(start))
                FocusLiveActivityManager.shared.update(elapsedSeconds: elapsed)
                print("[StatsManager] Synced Live Activity to \(elapsed)s after foreground")
            }
            
            // Update total time saved
            updateTotalTimeSavedToday()
        }
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
