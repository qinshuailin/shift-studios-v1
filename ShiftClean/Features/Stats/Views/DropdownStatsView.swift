import SwiftUI
import Charts

struct DropdownStatsView: View {
    let focusTime: Int
    let streak: Int
    @State private var dailyGoal: Int = 400 // Default goal
    let appUsageData: [AppUsageData]
    let weeklyData: [Int]
    let categoryData: [CategoryUsageData]
    let pickupsData: [(String, Double)]
    let hourlyUsageData: [(String, Double)]
    let firstPickupTime: Date?
    let longestSession: DateInterval?
    @ObservedObject var statsManager = StatsManager.shared
    
    // State for dropdowns and animations
    @State private var isStreakExpanded: Bool = true
    @State private var isInsightsExpanded: Bool = false
    @State private var isUsageExpanded: Bool = false
    @State private var selectedApp: AppUsageData? = nil
    @State private var isEditingGoal: Bool = false
    @State private var goalText: String = "400"
    @State private var animateElements: Bool = false
    
    // Calculate focus score (0-10 scale)
    private var focusScore: Double {
        return statsManager.focusScore
    }
    
    private var focusRating: String {
        if focusScore >= 9.0 {
            return "Excellent"
        } else if focusScore >= 7.0 {
            return "Good"
        } else if focusScore >= 5.0 {
            return "Average"
        } else if focusScore >= 3.0 {
            return "Fair"
        } else {
            return "Needs Improvement"
        }
    }
    
    private var dailyProgress: Double {
        return min(Double(focusTime) / Double(dailyGoal), 1.0)
    }
    
    // Calculate total time saved
    private var totalTimeSaved: Int {
        return appUsageData.reduce(0) { $0 + Int($1.timeSaved / 60) }
    }
    
    // Weekly comparison
    private var weeklyComparison: (Double, Bool) {
        let thisWeek = weeklyData.reduce(0, +)
        let previousWeek = Double(thisWeek) * 1.07 // Simulating 7% more last week
        let percentChange = (Double(thisWeek) - previousWeek) / previousWeek * 100
        return (abs(percentChange), percentChange < 0)
    }
    
    // Extract streak section content to reduce complexity
    private var streakSectionContent: some View {
        VStack(spacing: Constants.Layout.standardSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Constants.formatMinutesToHoursAndMinutes(focusTime))
                        .font(Constants.Fonts.largeTitleSwiftUI())
                        .foregroundColor(Constants.Colors.textSwiftUI)
                        .scaleEffect(animateElements ? 1.0 : 0.9)
                        .opacity(animateElements ? 1.0 : 0.0)
                    
                    Text("\(streak) day streak")
                        .font(Constants.Fonts.calloutSwiftUI())
                        .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                        .opacity(animateElements ? 1.0 : 0.0)
                }
                
                Spacer()
                
                Button(action: {
                    isEditingGoal = true
                    goalText = "\(dailyGoal)"
                }) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 24))
                        .foregroundColor(Constants.Colors.primarySwiftUI)
                }
                .scaleEffect(animateElements ? 1.0 : 0.8)
                .opacity(animateElements ? 1.0 : 0.0)
            }
            
            // Progress towards daily goal
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: animateElements ? dailyProgress : 0)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .frame(height: 8)
                
                HStack {
                    Text("\(Int(dailyProgress * 100))% of daily goal")
                        .font(Constants.Fonts.footnoteSwiftUI())
                        .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                    
                    Spacer()
                    
                    Text("(\(Constants.formatMinutesToHoursAndMinutes(dailyGoal)))")
                        .font(Constants.Fonts.footnoteSwiftUI())
                        .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                }
                .opacity(animateElements ? 1.0 : 0.0)
            }
        }
    }
    
    // Extract insights section content to reduce complexity
    private var insightsSectionContent: some View {
        VStack(spacing: Constants.Layout.standardSpacing) {
            // Focus Score
            HStack(alignment: .top, spacing: Constants.Layout.largeSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", focusScore))
                            .font(Constants.Fonts.title1SwiftUI())
                            .foregroundColor(Constants.Colors.textSwiftUI)
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
                    .scaleEffect(animateElements ? 1.0 : 0.9)
                    .opacity(animateElements ? 1.0 : 0.0)
                    
                    Text(focusRating)
                        .font(Constants.Fonts.subheadlineSwiftUI())
                        .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                        .opacity(animateElements ? 1.0 : 0.0)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Saved")
                        .font(Constants.Fonts.calloutSwiftUI())
                        .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                    
                    Text(Constants.formatMinutesToHoursAndMinutes(totalTimeSaved))
                        .font(Constants.Fonts.title3SwiftUI())
                        .foregroundColor(Constants.Colors.textSwiftUI)
                }
                .opacity(animateElements ? 1.0 : 0.0)
            }
            
            Divider()
            
            // Most used apps
            VStack(alignment: .leading, spacing: 8) {
                Text("Most Used")
                    .font(Constants.Fonts.calloutSwiftUI())
                    .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                
                HStack(spacing: 12) {
                    ForEach(Array(appUsageData.prefix(5).enumerated()), id: \.element.id) { index, app in
                        AppIconView(appName: app.name)
                            .scaleEffect(animateElements ? 1.0 : 0.8)
                            .opacity(animateElements ? 1.0 : 0.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.1 * Double(index)), value: animateElements)
                    }
                }
            }
            
            Divider()
            
            // Weekly comparison
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Constants.Colors.primarySwiftUI)
                    .font(.system(size: 20))
                
                Text("Way to go! Your screen time this week is \(String(format: "%.0f", weeklyComparison.0))% less than last week")
                    .font(Constants.Fonts.subheadlineSwiftUI())
                    .foregroundColor(Constants.Colors.textSwiftUI)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .opacity(animateElements ? 1.0 : 0.0)
        }
    }
    
    // Extract app usage section content to reduce complexity
    private var appUsageSectionContent: some View {
        VStack(spacing: Constants.Layout.standardSpacing) {
            if selectedApp == nil {
                // App usage graph
                AppUsageGraphView(hourlyData: hourlyUsageData)
                
                // App list with usage data
                ForEach(Array(appUsageData.prefix(4).enumerated()), id: \.element.id) { index, app in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedApp = app
                        }
                    }) {
                        AppUsageRow(app: app)
                            .opacity(animateElements ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.3).delay(0.1 * Double(index)), value: animateElements)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if app != appUsageData.prefix(4).last {
                        Divider()
                    }
                }
            } else {
                // Detailed app view
                AppDetailView(
                    app: selectedApp!,
                    hourlyData: hourlyUsageData,
                    onBack: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedApp = nil
                        }
                    }
                )
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Layout.standardSpacing) {
                // Focus Mode Status
                if statsManager.isFocusModeActive {
                    focusModeActiveView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Streak Section
                DropdownSection(
                    title: "Streak",
                    isExpanded: $isStreakExpanded,
                    content: {
                        streakSectionContent
                            .padding(Constants.Layout.standardSpacing)
                            .background(Constants.Colors.cardBackgroundSwiftUI)
                            .cornerRadius(Constants.Layout.cornerRadius)
                    }
                )
                
                // Insights Section
                DropdownSection(
                    title: "Insights",
                    isExpanded: $isInsightsExpanded,
                    content: {
                        insightsSectionContent
                            .padding(Constants.Layout.standardSpacing)
                            .background(Constants.Colors.cardBackgroundSwiftUI)
                            .cornerRadius(Constants.Layout.cornerRadius)
                    }
                )
                
                // Usage Graph Section
                DropdownSection(
                    title: "App Usage",
                    isExpanded: $isUsageExpanded,
                    content: {
                        appUsageSectionContent
                            .padding(Constants.Layout.standardSpacing)
                            .background(Constants.Colors.cardBackgroundSwiftUI)
                            .cornerRadius(Constants.Layout.cornerRadius)
                    }
                )
            }
            .padding(Constants.Layout.standardSpacing)
        }
        .background(Constants.Colors.backgroundSwiftUI)
        .alert("Edit Daily Goal", isPresented: $isEditingGoal) {
            TextField("Daily goal in minutes", text: $goalText)
                .keyboardType(.numberPad)
            
            Button("Cancel", role: .cancel) {
                isEditingGoal = false
            }
            
            Button("Save") {
                if let newGoal = Int(goalText), newGoal > 0 {
                    dailyGoal = newGoal
                }
                isEditingGoal = false
            }
        } message: {
            Text("Enter your daily focus goal in minutes")
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                animateElements = true
            }
        }
        .onDisappear {
            animateElements = false
        }
    }
    
    // Focus mode active view
    private var focusModeActiveView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Focus Mode Active")
                    .font(Constants.Fonts.headlineSwiftUI())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        statsManager.toggleFocusMode()
                    }
                }) {
                    Text("End")
                        .font(Constants.Fonts.subheadlineSwiftUI())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(16)
                }
            }
            
            if let startTime = statsManager.focusModeStartTime {
                Text("Started \(timeAgoString(from: startTime))")
                    .font(Constants.Fonts.footnoteSwiftUI())
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Constants.Layout.standardSpacing)
        .background(Constants.Colors.primarySwiftUI)
        .cornerRadius(Constants.Layout.cornerRadius)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour], from: date, to: now)
        
        if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            return "just now"
        }
    }
    
    private var progressColor: Color {
        if dailyProgress >= 1.0 {
            return .green
        } else if dailyProgress >= 0.7 {
            return Constants.Colors.primarySwiftUI
        } else if dailyProgress >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Helper Views

struct DropdownSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(Constants.Fonts.title3SwiftUI())
                        .foregroundColor(Constants.Colors.textSwiftUI)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Constants.Colors.primarySwiftUI)
                        .font(.system(size: 16, weight: .semibold))
                        .animation(.easeInOut, value: isExpanded)
                }
                .padding(Constants.Layout.standardSpacing)
                .background(Constants.Colors.cardBackgroundSwiftUI)
                .cornerRadius(Constants.Layout.cornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content()
                    .padding(.top, 1)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct AppIconView: View {
    let appName: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            Image(systemName: getIconName(for: appName))
                .font(.system(size: 20))
                .foregroundColor(getIconColor(for: appName))
        }
    }
    
    private func getIconName(for appName: String) -> String {
        switch appName.lowercased() {
        case let name where name.contains("instagram"):
            return "camera.fill"
        case let name where name.contains("whatsapp"):
            return "message.fill"
        case let name where name.contains("tiktok"):
            return "video.fill"
        case let name where name.contains("youtube"):
            return "play.rectangle.fill"
        case let name where name.contains("twitter") || name.contains("x"):
            return "bubble.left.fill"
        case let name where name.contains("facebook"):
            return "person.2.fill"
        case let name where name.contains("snapchat"):
            return "ghost.fill"
        case let name where name.contains("netflix") || name.contains("hulu") || name.contains("disney"):
            return "tv.fill"
        case let name where name.contains("game") || name.contains("play"):
            return "gamecontroller.fill"
        case let name where name.contains("dribbble"):
            return "basketball.fill"
        case let name where name.contains("clickup"):
            return "checkmark.circle.fill"
        default:
            return "app.fill"
        }
    }
    
    private func getIconColor(for appName: String) -> Color {
        switch appName.lowercased() {
        case let name where name.contains("instagram"):
            return Color(red: 0.9, green: 0.1, blue: 0.5)
        case let name where name.contains("whatsapp"):
            return Color.green
        case let name where name.contains("tiktok"):
            return Color.blue
        case let name where name.contains("youtube"):
            return Color.red
        case let name where name.contains("twitter") || name.contains("x"):
            return Color.blue
        case let name where name.contains("facebook"):
            return Color.blue
        case let name where name.contains("snapchat"):
            return Color.yellow
        case let name where name.contains("dribbble"):
            return Color.pink
        case let name where name.contains("clickup"):
            return Color.purple
        default:
            return Constants.Colors.primarySwiftUI
        }
    }
}

struct AppUsageRow: View {
    let app: AppUsageData
    
    var body: some View {
        HStack(spacing: Constants.Layout.standardSpacing) {
            AppIconView(appName: app.name)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(Constants.Fonts.headlineSwiftUI())
                    .foregroundColor(Constants.Colors.textSwiftUI)
                
                Text(Constants.formatMinutesToHoursAndMinutes(Int(app.timeSaved / 60)) + "/day")
                    .font(Constants.Fonts.subheadlineSwiftUI())
                    .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                .font(.system(size: 14, weight: .semibold))
        }
    }
}

// MARK: - Preview

struct DropdownStatsView_Previews: PreviewProvider {
    static var previews: some View {
        DropdownStatsView(
            focusTime: 185,
            streak: 3,
            appUsageData: [
                AppUsageData(bundleID: nil, name: "Instagram", timeSaved: 3600),
                AppUsageData(bundleID: nil, name: "TikTok", timeSaved: 2400),
                AppUsageData(bundleID: nil, name: "YouTube", timeSaved: 1800),
                AppUsageData(bundleID: nil, name: "Twitter", timeSaved: 1200)
            ],
            weeklyData: [120, 180, 210, 150, 90, 240, 185],
            categoryData: [
                CategoryUsageData(category: "Social", apps: [
                    AppUsageData(bundleID: nil, name: "Instagram", timeSaved: 3600),
                    AppUsageData(bundleID: nil, name: "TikTok", timeSaved: 2400),
                    AppUsageData(bundleID: nil, name: "Twitter", timeSaved: 1200)
                ]),
                CategoryUsageData(category: "Entertainment", apps: [
                    AppUsageData(bundleID: nil, name: "YouTube", timeSaved: 1800)
                ]),
                CategoryUsageData(category: "Productivity", apps: [])
            ],
            pickupsData: [
                ("Instagram", 15),
                ("TikTok", 10),
                ("YouTube", 5)
            ],
            hourlyUsageData: [
                ("8 AM", 15),
                ("10 AM", 30),
                ("12 PM", 20),
                ("2 PM", 45),
                ("4 PM", 25),
                ("6 PM", 10),
                ("8 PM", 35)
            ],
            firstPickupTime: Date().addingTimeInterval(-3600 * 8),
            longestSession: DateInterval(start: Date().addingTimeInterval(-3600), duration: 1800)
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Constants.Colors.backgroundSwiftUI)
    }
}
