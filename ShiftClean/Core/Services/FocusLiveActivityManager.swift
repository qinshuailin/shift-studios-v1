import ActivityKit
import Foundation // <-- Add this for Date

class FocusLiveActivityManager {
    static let shared = FocusLiveActivityManager()
    private var activity: Activity<FocusTimerAttributes>?
    private var isStarting = false
    private var lastUpdateTime: Date?
    
    // NUCLEAR PROTECTION: Multiple resurrection mechanisms
    private var resurrectionTimer: Timer?
    private var updateFailureCount = 0
    private let maxFailureCount = 3

    // Start with better concurrency protection
    func start(goalMinutes: Int) {
        Task { @MainActor in
            guard !isStarting else {
                print("[FocusLiveActivityManager] Already starting, ignoring")
                return
            }
            isStarting = true
            defer { isStarting = false }
            
            // Aggressively clean up existing activities
            await cleanupExistingActivities()
            
            let initialState = FocusTimerAttributes.ContentState(elapsedSeconds: 0, isActive: true)
            let attributes = FocusTimerAttributes(goalMinutes: goalMinutes)
            
            do {
                self.activity = try Activity<FocusTimerAttributes>.request(
                    attributes: attributes,
                    content: .init(state: initialState, staleDate: nil),
                    pushType: nil
                )
                self.lastUpdateTime = Date()
                print("[FocusLiveActivityManager] Started Live Activity: \(goalMinutes) min goal")
            } catch {
                print("[FocusLiveActivityManager] Failed to start Live Activity: \(error)")
            }
        }
    }

    // Update with NO THROTTLING - ALWAYS UPDATE
    func update(elapsedSeconds: Int) {
        // REMOVED THROTTLING - UPDATE EVERY SINGLE TIME
        print("[FocusLiveActivityManager] Updating Live Activity: \(elapsedSeconds)s")
        
        Task { @MainActor in
            guard let activity = self.activity else {
                print("[FocusLiveActivityManager] No activity to update, restarting")
                // BULLETPROOF: If no activity, try to restart it
                await self.attemptActivityRestart(elapsedSeconds: elapsedSeconds)
                return
            }
            
            // Create state with LONG stale date to prevent iOS throttling
            let state = FocusTimerAttributes.ContentState(elapsedSeconds: elapsedSeconds, isActive: true)
            let staleDate = Date().addingTimeInterval(300) // Keep fresh for 5 minutes
            
            do {
                await activity.update(.init(state: state, staleDate: staleDate))
                self.lastUpdateTime = Date()
                self.updateFailureCount = 0 // Reset failure count on success
                print("[FocusLiveActivityManager] Updated to \(elapsedSeconds)s")
                
                // NUCLEAR PROTECTION: Start resurrection timer on first successful update
                self.startResurrectionTimer()
                
            } catch {
                self.updateFailureCount += 1
                print("[FocusLiveActivityManager] Update failed (\(self.updateFailureCount)/\(self.maxFailureCount)): \(error)")
                
                // NUCLEAR ESCALATION: If too many failures, go nuclear
                if self.updateFailureCount >= self.maxFailureCount {
                    print("[FocusLiveActivityManager] NUCLEAR MODE ACTIVATED - Too many failures")
                    await self.activateNuclearMode(goalMinutes: activity.attributes.goalMinutes, currentSeconds: elapsedSeconds)
                } else {
                    // BULLETPROOF: Multiple recovery strategies
                    await self.attemptRecovery(goalMinutes: activity.attributes.goalMinutes, currentSeconds: elapsedSeconds, error: error)
                }
            }
        }
    }

    // End with proper cleanup
    func end(finalElapsedSeconds: Int) {
        Task { @MainActor in
            let state = FocusTimerAttributes.ContentState(elapsedSeconds: finalElapsedSeconds, isActive: false)
            if let activity = self.activity {
                if #available(iOS 16.2, *) {
                    await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
                } else {
                    await activity.end(using: state, dismissalPolicy: .immediate)
                }
            }
            await cleanupExistingActivities()
            self.activity = nil
            self.lastUpdateTime = nil
            
            // Stop nuclear protection when ending
            stopNuclearProtection()
            
            print("[FocusLiveActivityManager] Ended Live Activity")
        }
    }
    
    // Aggressive cleanup helper
    private func cleanupExistingActivities() async {
        for activity in Activity<FocusTimerAttributes>.activities {
            if #available(iOS 16.2, *) {
                await activity.end(.init(state: .init(elapsedSeconds: 0, isActive: false), staleDate: nil), dismissalPolicy: .immediate)
            } else {
                await activity.end(using: .init(elapsedSeconds: 0, isActive: false), dismissalPolicy: .immediate)
            }
        }
        // Wait for cleanup to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        // Double check and force cleanup if needed
        if !Activity<FocusTimerAttributes>.activities.isEmpty {
            print("[FocusLiveActivityManager] Cleaning up remaining activities")
            for activity in Activity<FocusTimerAttributes>.activities {
                if #available(iOS 16.2, *) {
                    await activity.end(.init(state: .init(elapsedSeconds: 0, isActive: false), staleDate: nil), dismissalPolicy: .immediate)
                } else {
                    await activity.end(using: .init(elapsedSeconds: 0, isActive: false), dismissalPolicy: .immediate)
                }
            }
        }
    }

    // Utility: Check if any Live Activity is active
    func isLiveActivityActive() -> Bool {
        return !Activity<FocusTimerAttributes>.activities.isEmpty
    }

    // Debug: Print all running Live Activities
    func printAllLiveActivities() {
        for activity in Activity<FocusTimerAttributes>.activities {
            print("Live Activity: \(activity.id), state: \(activity.activityState), attributes: \(activity.attributes)")
        }
    }
    
    // Refresh activity if it becomes unresponsive
    private func refreshActivity(goalMinutes: Int, currentSeconds: Int) async {
                    print("[FocusLiveActivityManager] Refreshing unresponsive Live Activity")
        
        // End current activity
        if let activity = self.activity {
            if #available(iOS 16.2, *) {
                await activity.end(.init(state: .init(elapsedSeconds: currentSeconds, isActive: false), staleDate: nil), dismissalPolicy: .immediate)
            } else {
                await activity.end(using: .init(elapsedSeconds: currentSeconds, isActive: false), dismissalPolicy: .immediate)
            }
        }
        
        // Wait a moment
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Start new activity with current progress
        let initialState = FocusTimerAttributes.ContentState(elapsedSeconds: currentSeconds, isActive: true)
        let attributes = FocusTimerAttributes(goalMinutes: goalMinutes)
        
        do {
            self.activity = try Activity<FocusTimerAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: Date().addingTimeInterval(30)),
                pushType: nil
            )
            self.lastUpdateTime = Date()
                            print("[FocusLiveActivityManager] Refreshed Live Activity: \(currentSeconds)s")
        } catch {
            print("[FocusLiveActivityManager] Failed to refresh Live Activity: \(error)")
        }
    }
    
    // BULLETPROOF: Attempt to restart activity if it's missing
    private func attemptActivityRestart(elapsedSeconds: Int) async {
        print("[FocusLiveActivityManager] Attempting activity restart")
        
        // Try to find existing activities first
        let existingActivities = Activity<FocusTimerAttributes>.activities
        if let existingActivity = existingActivities.first {
                            print("[FocusLiveActivityManager] Found existing activity, using it")
            self.activity = existingActivity
            self.lastUpdateTime = Date()
            return
        }
        
        // If no existing activity, create new one with current progress
        let goalMinutes = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        let goal = goalMinutes > 0 ? goalMinutes : 120
        
        let initialState = FocusTimerAttributes.ContentState(elapsedSeconds: elapsedSeconds, isActive: true)
        let attributes = FocusTimerAttributes(goalMinutes: goal)
        
        do {
            self.activity = try Activity<FocusTimerAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: Date().addingTimeInterval(300)),
                pushType: nil
            )
            self.lastUpdateTime = Date()
                            print("[FocusLiveActivityManager] Restarted activity: \(elapsedSeconds)s")
        } catch {
            print("[FocusLiveActivityManager] Failed to restart activity: \(error)")
        }
    }
    
    // BULLETPROOF: Multiple recovery strategies when updates fail
    private func attemptRecovery(goalMinutes: Int, currentSeconds: Int, error: Error) async {
        print("[FocusLiveActivityManager] Attempting recovery from error: \(error)")
        
        // Strategy 1: Try update again immediately
        if let activity = self.activity {
            let state = FocusTimerAttributes.ContentState(elapsedSeconds: currentSeconds, isActive: true)
            do {
                await activity.update(.init(state: state, staleDate: Date().addingTimeInterval(300)))
                print("[FocusLiveActivityManager] Recovery update successful")
                self.lastUpdateTime = Date()
                return
            } catch {
                print("[FocusLiveActivityManager] Recovery update failed: \(error)")
            }
        }
        
        // Strategy 2: Full refresh of the activity
        await refreshActivity(goalMinutes: goalMinutes, currentSeconds: currentSeconds)
    }
    
    // NUCLEAR PROTECTION LEVEL 1: Resurrection Timer
    private func startResurrectionTimer() {
        // Kill any existing resurrection timer
        resurrectionTimer?.invalidate()
        
        // Start resurrection timer - checks every 60 seconds if Live Activity is still alive
        resurrectionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkLiveActivityHealth()
        }
        
        if let timer = resurrectionTimer {
            RunLoop.main.add(timer, forMode: .common)
            RunLoop.main.add(timer, forMode: .default)
        }
        
        print("[FocusLiveActivityManager] Resurrection timer activated")
    }
    
    private func checkLiveActivityHealth() {
        // Check if Live Activity is still responsive
        guard let activity = self.activity else {
            print("[FocusLiveActivityManager] Resurrection check: No activity found")
            return
        }
        
        // Check if we haven't updated in a while
        if let lastUpdate = lastUpdateTime {
            let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
            if timeSinceUpdate > 120 { // No update for 2 minutes
                print("[FocusLiveActivityManager] Resurrection check: Activity dead for \(timeSinceUpdate)s")
                
                // Try to resurrect with current elapsed time from StatsManager
                Task {
                    if let start = UserDefaults.standard.object(forKey: "focusModeStartTime") as? Date {
                        let elapsed = Int(Date().timeIntervalSince(start))
                        await self.attemptActivityRestart(elapsedSeconds: elapsed)
                    }
                }
            }
        }
    }
    
    // NUCLEAR PROTECTION LEVEL 2: Nuclear Mode Activation
    private func activateNuclearMode(goalMinutes: Int, currentSeconds: Int) async {
        print("[FocusLiveActivityManager] 🚨 NUCLEAR MODE ACTIVATED 🚨")
        print("[FocusLiveActivityManager] Deploying all available countermeasures")
        
        // NUCLEAR STRATEGY 1: Scorched Earth - Kill everything and rebuild
        await cleanupExistingActivities()
        self.activity = nil
        self.updateFailureCount = 0
        
        // Wait for total cleanup
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // NUCLEAR STRATEGY 2: Force restart with maximum priority
        let initialState = FocusTimerAttributes.ContentState(elapsedSeconds: currentSeconds, isActive: true)
        let attributes = FocusTimerAttributes(goalMinutes: goalMinutes)
        
        // Try up to 5 times to restart
        for attempt in 1...5 {
            do {
                self.activity = try Activity<FocusTimerAttributes>.request(
                    attributes: attributes,
                    content: .init(state: initialState, staleDate: Date().addingTimeInterval(600)), // 10 minute stale date
                    pushType: nil
                )
                
                self.lastUpdateTime = Date()
                print("[FocusLiveActivityManager] 🚀 NUCLEAR RESTART SUCCESSFUL on attempt \(attempt)")
                
                // NUCLEAR STRATEGY 3: Triple-redundant immediate updates
                for i in 0..<3 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second between
                    let redundantState = FocusTimerAttributes.ContentState(elapsedSeconds: currentSeconds + i, isActive: true)
                    try? await self.activity?.update(.init(state: redundantState, staleDate: Date().addingTimeInterval(600)))
                }
                
                return // Success!
                
            } catch {
                print("[FocusLiveActivityManager] Nuclear restart attempt \(attempt) failed: \(error)")
                if attempt < 5 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds before retry
                }
            }
        }
        
        print("[FocusLiveActivityManager] 💀 NUCLEAR MODE FAILED - All attempts exhausted")
        
        // NUCLEAR STRATEGY 4: Last resort - Save state and pray
        UserDefaults.standard.set(currentSeconds, forKey: "nuclearModeElapsed")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "nuclearModeTimestamp")
        UserDefaults.standard.set(goalMinutes, forKey: "nuclearModeGoal")
    }
    
    // NUCLEAR PROTECTION LEVEL 3: Stop all protection
    func stopNuclearProtection() {
        resurrectionTimer?.invalidate()
        resurrectionTimer = nil
        updateFailureCount = 0
        print("[FocusLiveActivityManager] Nuclear protection deactivated")
    }
}
