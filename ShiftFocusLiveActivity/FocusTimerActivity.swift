import ActivityKit
import WidgetKit
import SwiftUI
// Import the shared FocusTimerAttributes model if needed
// import ShiftClean // Uncomment if using a module

struct FocusTimerLiveActivityView: View {
    let context: ActivityViewContext<FocusTimerAttributes>

    var body: some View {
        VStack(spacing: 8) {
            Text(context.attributes.goalMinutes > 0 ? "focus mode" : "session ended")
                .font(.headline)
                .foregroundColor(.black)
            Text(timerString(from: context.state.elapsedSeconds))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
            if context.state.isActive {
                Text("work hard, play harder.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
    }

    private func timerString(from seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

struct FocusTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            FocusTimerLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland(
                expanded: {
                    DynamicIslandExpandedRegion(.center) {
                        VStack(spacing: 4) {
                            Text("focus mode")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(timerString(from: context.state.elapsedSeconds))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                },
                compactLeading: {
                    Text(timerString(from: context.state.elapsedSeconds))
                        .font(.caption)
                        .fontWeight(.semibold)
                },
                compactTrailing: {
                    Text("focus")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                },
                minimal: {
                    Text("focus")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            )
        }
    }
    
    private func timerString(from seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

