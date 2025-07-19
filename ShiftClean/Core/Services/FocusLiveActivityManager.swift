import ActivityKit

class FocusLiveActivityManager {
    static let shared = FocusLiveActivityManager()
    private var activity: Activity<FocusTimerAttributes>?

    // Utility: Check if any Live Activity is active
    func isLiveActivityActive() -> Bool {
        return !Activity<FocusTimerAttributes>.activities.isEmpty
    }

    // Start the Live Activity
    func start(goalMinutes: Int) {
        Task {
            // End all existing activities before starting a new one
            for activity in Activity<FocusTimerAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
            // Wait a moment to ensure cleanup
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            if !Activity<FocusTimerAttributes>.activities.isEmpty {
                print("[FocusLiveActivityManager] A Live Activity is still running, not starting a new one.")
                return
            }
            let initialState = FocusTimerAttributes.ContentState(elapsedSeconds: 0, isActive: true)
            let attributes = FocusTimerAttributes(goalMinutes: goalMinutes)
            do {
                self.activity = try Activity<FocusTimerAttributes>.request(
                    attributes: attributes,
                    content: .init(state: initialState, staleDate: nil),
                    pushType: nil
                )
                print("[FocusLiveActivityManager] Started new Live Activity with goal: \(goalMinutes) min")
            } catch {
                print("[FocusLiveActivityManager] Failed to start Live Activity: \(error)")
            }
        }
    }

    // Update the Live Activity (call this every second/minute)
    func update(elapsedSeconds: Int) {
        Task {
            let state = FocusTimerAttributes.ContentState(elapsedSeconds: elapsedSeconds, isActive: true)
            await activity?.update(using: state)
        }
    }

    // End the Live Activity
    func end(finalElapsedSeconds: Int) {
        Task {
            let state = FocusTimerAttributes.ContentState(elapsedSeconds: finalElapsedSeconds, isActive: false)
            await activity?.end(using: state, dismissalPolicy: .immediate)
        }
    }

    // Debug: Print all running Live Activities
    func printAllLiveActivities() {
        for activity in Activity<FocusTimerAttributes>.activities {
            print("Live Activity: \(activity.id), state: \(activity.activityState), attributes: \(activity.attributes)")
        }
    }
} 
