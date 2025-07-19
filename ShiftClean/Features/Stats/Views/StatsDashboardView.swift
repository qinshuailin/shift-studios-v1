import SwiftUI
import DeviceActivity

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

struct StatsDashboardView: View {
    @ObservedObject var statsManager: StatsManager = .shared
    @State private var timer: Timer? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("stats")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 16)

                HStack(spacing: 12) {
                    StatsDashboardCard(
                        title: "streak",
                        value: "\(statsManager.currentStreak) days",
                        icon: "flame.fill",
                        color: .gray
                    )
                    StatsDashboardCard(
                        title: "daily goal",
                        value: "\(statsManager.dailyGoal) min",
                        icon: "target",
                        color: .gray
                    )
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    StatsDashboardCard(
                        title: "time saved",
                        value: statsManager.timeSavedString,
                        icon: "checkmark.seal.fill",
                        color: .gray
                    )
                    StatsDashboardCard(
                        title: "screen time",
                        value: statsManager.timeWastedString,
                        icon: "clock.fill",
                        color: .gray
                    )
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 6) {
                    Text("today's focus progress")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                    ProgressView(value: statsManager.progressToGoal)
                        .accentColor(.gray)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .background(Color.white)
                        .cornerRadius(4)
                    Text("\(statsManager.timeSavedString) / \(statsManager.dailyGoal) min")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))

                VStack(alignment: .leading, spacing: 6) {
                    Text("most used apps")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                    if statsManager.mostUsedApps.isEmpty {
                        Text("no usage data available yet.")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.vertical)
                    } else {
                        ForEach(statsManager.mostUsedApps.prefix(5)) { app in
                            AppUsageRow(app: app)
                                .background(Color.white)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))

                if let lastUpdated = statsManager.lastUpdated {
                    Text("last updated: \(lastUpdated, formatter: dateFormatter)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }

                let filter = DeviceActivityFilter(
                    segment: .daily(
                        during: Calendar.current.dateInterval(of: .day, for: Date())!
                    )
                )
                DeviceActivityReport(.totalActivity, filter: filter)
                    .frame(maxHeight: 400)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            }
            .padding(.vertical)
            .background(Color.white)
        }
        .background(Color.white)
        .onAppear {
            startTimer()
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { _ in
                statsManager.loadData()
            }
        }
        .onDisappear {
            stopTimer()
            NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            statsManager.loadData()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct StatsDashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                Spacer()
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
        .frame(maxWidth: .infinity)
    }
}
