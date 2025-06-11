import SwiftUI
import Charts

struct StatsView: View {
    let screenTime: Int // in minutes
    let timeSaved: Int // in minutes
    let dailyGoal: Int // in minutes
    let streak: Int // in days
    @State private var isEditingGoal: Bool = false
    @State private var goalText: String = ""
    @State private var animateElements: Bool = false
    
    // Weekly data for chart
    let weeklyData: [Int]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("stats")
                    .font(.system(size: 48, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).delay(0.1), value: animateElements)
                
                // Screen Time Card
                StatCard(title: "SCREEN TIME") {
                    VStack(alignment: .center, spacing: 16) {
                        // Chart
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(0..<7, id: \.self) { index in
                                let value = weeklyData.count > index ? weeklyData[index] : 0
                                let maxValue = weeklyData.max() ?? 1
                                let height = CGFloat(value) / CGFloat(maxValue) * 60
                                
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 20, height: max(height, 10))
                                    .cornerRadius(2)
                                    .scaleEffect(animateElements ? 1 : 0.5, anchor: .bottom)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2 + Double(index) * 0.05), value: animateElements)
                            }
                        }
                        .frame(height: 60, alignment: .bottom)
                        .padding(.horizontal)
                        
                        // Time value
                        Text("\(screenTime / 60)h \(screenTime % 60)m")
                            .font(.system(size: 48, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .opacity(animateElements ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(0.3), value: animateElements)
                    }
                }
                
                // Time Saved Card
                StatCard(title: "TIME SAVED") {
                    Text("\(timeSaved / 60)h \(timeSaved % 60)m")
                        .font(.system(size: 48, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.4), value: animateElements)
                }
                
                // Bottom row with two cards
                HStack(spacing: 16) {
                    // Daily Goal Card
                    StatCard(title: "DAILY GOAL") {
                        HStack {
                            Text("\(dailyGoal / 60)h \(dailyGoal % 60)m")
                                .font(.system(size: 36, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .opacity(animateElements ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5).delay(0.5), value: animateElements)
                            
                            Button(action: {
                                goalText = "\(dailyGoal)"
                                isEditingGoal = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18))
                                    .foregroundColor(.black)
                            }
                            .opacity(animateElements ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(0.5), value: animateElements)
                        }
                    }
                    
                    // Streak Card
                    StatCard(title: "STREAK") {
                        HStack {
                            Text("\(streak)")
                                .font(.system(size: 36, weight: .bold))
                            
                            Text("days")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.6), value: animateElements)
                    }
                }
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .padding(.horizontal)
        }
        .background(Color.white)
        .onAppear {
            withAnimation {
                animateElements = true
            }
        }
        .alert("Edit Daily Goal", isPresented: $isEditingGoal) {
            TextField("Daily goal in minutes", text: $goalText)
                .keyboardType(.numberPad)
            
            Button("Cancel", role: .cancel) {
                isEditingGoal = false
            }
            
            Button("Save") {
                if let newGoal = Int(goalText), newGoal > 0 {
                    // Update goal in StatsManager
                    StatsManager.shared.updateDailyGoal(newGoal)
                }
                isEditingGoal = false
            }
        } message: {
            Text("Enter your daily focus goal in minutes")
        }
    }
}

struct StatCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .background(Color.white)
        )
        .cornerRadius(12)
    }
}

// Preview provider
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(
            screenTime: 225, // 3h 45m
            timeSaved: 80,   // 1h 20m
            dailyGoal: 120,  // 2h 0m
            streak: 5,
            weeklyData: [30, 35, 50, 40, 45, 60, 65]
        )
    }
}
