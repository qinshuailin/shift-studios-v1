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
        // Throttle updates to prevent overwhelming the system
        if let lastUpdate = lastUpdateTime, Date().timeIntervalSince(lastUpdate) < 0.9 {
            return // Skip if less than 0.9 seconds since last update
        }
        Task { @MainActor in
            guard let activity = self.activity else {
                print("[FocusLiveActivityManager] No activity to update")
                return
            }
            let state = FocusTimerAttributes.ContentState(elapsedSeconds: elapsedSeconds, isActive: true)
            do {
                await activity.update(using: state)
                self.lastUpdateTime = Date()
                // Only log every 10 seconds to avoid spam
                if elapsedSeconds % 10 == 0 {
                    print("[FocusLiveActivityManager] Updated Live Activity: \(elapsedSeconds)s")
                }
            } catch {
                print("[FocusLiveActivityManager] Failed to update Live Activity: \(error)")
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
} 
