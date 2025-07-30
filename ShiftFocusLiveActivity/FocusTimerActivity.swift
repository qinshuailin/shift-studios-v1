import ActivityKit
import WidgetKit
import SwiftUI
// Import the shared FocusTimerAttributes model if needed
// import ShiftClean // Uncomment if using a module

struct FocusTimerLiveActivityView: View {
    let context: ActivityViewContext<FocusTimerAttributes>

    var body: some View {
        // FULL WIDTH - no white side bars
        VStack(spacing: 8) { 
            Text(context.state.isActive ? "focus mode" : "session ended")
                .font(.system(size: 18, weight: .light, design: .default))
                .textCase(.uppercase)
                .foregroundColor(.black)
            Text(timerString(from: context.state.elapsedSeconds))
                .font(.system(size: 48, weight: .light, design: .default))
                .foregroundColor(.black)
            if context.state.isActive {
                Text("work hard, play harder.")
                    .font(.system(size: 16, weight: .light, design: .default))
                    .foregroundColor(.black.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill entire widget
        .padding(16)
        .clipped() // Ensure no overflow
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
            // WRAPPER TO ELIMINATE WHITE SIDE BARS
            ZStack {
                // FULL BACKGROUND - no white bars
                Color(red: 0.97, green: 0.95, blue: 0.91)
                    .ignoresSafeArea()
                
                FocusTimerLiveActivityView(context: context)
            }
        } dynamicIsland: { context in
            DynamicIsland(
                expanded: {
                    DynamicIslandExpandedRegion(.center) {
                        VStack(spacing: 6) {
                            Text("FOCUS MODE")
                                .font(.system(size: 12, weight: .light, design: .default))
                                .textCase(.uppercase)
                                .foregroundColor(.black.opacity(0.6))
                            Text(timerString(from: context.state.elapsedSeconds))
                                .font(.system(size: 32, weight: .light, design: .default))
                                .foregroundColor(.black)
                        }
                        .padding(12)
                        .background(Color(red: 0.97, green: 0.95, blue: 0.91))
                        .cornerRadius(12)
                    }
                },
                compactLeading: {
                    Text(timerString(from: context.state.elapsedSeconds))
                        .font(.system(size: 14, weight: .light, design: .default))
                        .foregroundColor(.white)
                },
                compactTrailing: {
                    Text("focus")
                        .font(.system(size: 12, weight: .light, design: .default))
                        .foregroundColor(.white.opacity(0.6))
                },
                minimal: {
                    Text("focus")
                        .font(.system(size: 10, weight: .light, design: .default))
                        .foregroundColor(.white.opacity(0.6))
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

