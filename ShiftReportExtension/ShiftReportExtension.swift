import DeviceActivity
import SwiftUI
import Foundation

@main
struct ShiftReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport()
    }
}

struct ReportView: View {
    let configuration: TotalActivityReport.Configuration
    var body: some View {
        VStack {
            Text("App Usage Report")
                .font(.title)
            List(configuration.appUsage.sorted(by: { $0.value > $1.value }), id: \ .key) { app, duration in
                HStack {
                    Text(app)
                    Spacer()
                    Text("\(Int(duration/60)) min")
                }
            }
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(Constants.Fonts.title3SwiftUI())
                .foregroundColor(Constants.Colors.textSwiftUI)
            Text(title)
                .font(Constants.Fonts.subheadlineSwiftUI())
                .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
        }
        .swissCard()
        .frame(maxWidth: .infinity)
    }
}
