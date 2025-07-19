import SwiftUI
import Charts

struct AppDetailView: View {
    let app: AppUsageData
    let hourlyData: [(String, Double)]
    let onBack: () -> Void
    @State private var animateChart: Bool = false
    
    var body: some View {
        VStack(spacing: Constants.Layout.standardSpacing) {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Back")
                    }
                    .foregroundColor(Constants.Colors.primarySwiftUI)
                }
                
                Spacer()
            }
            
            // App header
            HStack(spacing: Constants.Layout.standardSpacing) {
                AppIconView(appName: app.name)
                    .scaleEffect(animateChart ? 1.0 : 0.8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(Constants.Fonts.title3SwiftUI())
                        .foregroundColor(Constants.Colors.textSwiftUI)
                    
                    Text(app.category)
                        .font(Constants.Fonts.subheadlineSwiftUI())
                        .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                        .opacity(animateChart ? 1.0 : 0.0)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Stats with animations
            HStack(spacing: Constants.Layout.largeSpacing) {
                VStack {
                    Text(Constants.formatMinutesToHoursAndMinutes(Int(app.duration / 60)))
                        .font(Constants.Fonts.title3SwiftUI())
                        .foregroundColor(Constants.Colors.textSwiftUI)
                        .opacity(animateChart ? 1.0 : 0.0)
                    
                    Text("Time Saved")
                        .font(Constants.Fonts.footnoteSwiftUI())
                        .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text("\(app.numberOfPickups)")
                        .font(Constants.Fonts.title3SwiftUI())
                        .foregroundColor(Constants.Colors.textSwiftUI)
                        .opacity(animateChart ? 1.0 : 0.0)
                    
                    Text("Pickups")
                        .font(Constants.Fonts.footnoteSwiftUI())
                        .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text("\(app.numberOfNotifications)")
                        .font(Constants.Fonts.title3SwiftUI())
                        .foregroundColor(Constants.Colors.textSwiftUI)
                        .opacity(animateChart ? 1.0 : 0.0)
                    
                    Text("Notifications")
                        .font(Constants.Fonts.footnoteSwiftUI())
                        .foregroundColor(Constants.Colors.secondaryTextSwiftUI)
                }
            }
            .padding(.vertical, Constants.Layout.standardSpacing)
            
            // Interactive usage chart
            AppUsageGraphView(hourlyData: hourlyData)
                .scaleEffect(animateChart ? 1.0 : 0.9)
                .opacity(animateChart ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateChart = true
            }
        }
        .onDisappear {
            animateChart = false
        }
    }
}
