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
                print("[FocusLiveActivityManager] Already starting, ignoring duplicate")
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
                print("[FocusLiveActivityManager] Started new Live Activity with goal: \(goalMinutes) min")
            } catch {
                print("[FocusLiveActivityManager] Failed to start Live Activity: \(error)")
            }
        }
    }

    // Update with throttling to prevent too many updates
    func update(elapsedSeconds: Int) {
        // More aggressive throttling - update every 5 seconds minimum
        if let lastUpdate = lastUpdateTime, Date().timeIntervalSince(lastUpdate) < 4.9 {
            return // Skip if less than 5 seconds since last update
        }
        
        Task { @MainActor in
            guard let activity = self.activity else {
                print("[FocusLiveActivityManager] No activity to update")
                return
            }
            
            // Create state with explicit stale date to keep it fresh
            let state = FocusTimerAttributes.ContentState(elapsedSeconds: elapsedSeconds, isActive: true)
            let staleDate = Date().addingTimeInterval(30) // Keep fresh for 30 seconds
            
            do {
                await activity.update(.init(state: state, staleDate: staleDate))
                self.lastUpdateTime = Date()
                
                // Log every 30 seconds to track updates
                if elapsedSeconds % 30 == 0 {
                    print("[FocusLiveActivityManager] Updated Live Activity: \(elapsedSeconds)s (staleDate: \(staleDate))")
                }
            } catch {
                print("[FocusLiveActivityManager] Failed to update Live Activity: \(error)")
                
                // If update fails, try to refresh the activity
                await refreshActivity(goalMinutes: activity.attributes.goalMinutes, currentSeconds: elapsedSeconds)
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
            print("[FocusLiveActivityManager] Forcing cleanup of remaining activities")
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
        print("[FocusLiveActivityManager] Refreshing unresponsive Live Activity...")
        
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
            print("[FocusLiveActivityManager] Successfully refreshed Live Activity with \(currentSeconds)s elapsed")
        } catch {
            print("[FocusLiveActivityManager] Failed to refresh Live Activity: \(error)")
        }
    }
} 
