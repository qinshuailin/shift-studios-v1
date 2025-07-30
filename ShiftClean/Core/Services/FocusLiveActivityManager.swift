import ActivityKit
import Foundation // <-- Add this for Date

class FocusLiveActivityManager {
    static let shared = FocusLiveActivityManager()
    private var activity: Activity<FocusTimerAttributes>?
    private var isStarting = false
    private var lastUpdateTime: Date?

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
                                    print("[FocusLiveActivityManager] Updated to \(elapsedSeconds)s")
            } catch {
                print("[FocusLiveActivityManager] Update failed: \(error)")
                
                // BULLETPROOF: Multiple recovery strategies
                await self.attemptRecovery(goalMinutes: activity.attributes.goalMinutes, currentSeconds: elapsedSeconds, error: error)
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
}
