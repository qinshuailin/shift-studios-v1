import SwiftUI
import Charts

struct AppUsageGraphView: View {
    let hourlyData: [(String, Double)]
    @State private var selectedHour: Int? = nil
    @State private var isAnimating: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Usage Pattern")
                .font(Constants.Fonts.headlineSwiftUI())
                .foregroundColor(Constants.Colors.textSwiftUI)
            
            chartContent
        }
    }
    
    // Break down the complex chart into a separate computed property
    private var chartContent: some View {
        Chart {
            ForEach(Array(hourlyData.enumerated()), id: \.element.0) { index, hourData in
                barMarkForHour(index: index, hourData: hourData)
            }
        }
        .frame(height: 200)
        .chartYScale(domain: 0...60)
        .chartOverlay { proxy in
            chartOverlayContent
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                isAnimating = true
            }
        }
    }
    
    // Extract bar mark creation to a separate method
    private func barMarkForHour(index: Int, hourData: (String, Double)) -> some ChartContent {
        BarMark(
            x: .value("Hour", hourData.0),
            y: .value("Minutes", isAnimating ? hourData.1 : 0)
        )
        .foregroundStyle(barMarkStyle(for: index))
        .cornerRadius(6)
        .annotation(position: .top) {
            annotationForHour(index: index, hourData: hourData)
        }
    }
    
    // Extract foreground style logic to a separate method
    private func barMarkStyle(for index: Int) -> Color {
        selectedHour == index 
            ? Constants.Colors.primarySwiftUI.opacity(0.8)
            : Constants.Colors.primarySwiftUI.opacity(0.6)
    }
    
    // Extract annotation view to a separate method
    @ViewBuilder
    private func annotationForHour(index: Int, hourData: (String, Double)) -> some View {
        if selectedHour == index {
            Text("\(Int(hourData.1)) min")
                .font(.caption)
                .foregroundColor(Constants.Colors.textSwiftUI)
                .padding(4)
                .background(Constants.Colors.cardBackgroundSwiftUI)
                .cornerRadius(4)
                .transition(.scale.combined(with: .opacity))
        }
    }
    
    // Extract chart overlay content to a separate computed property
    private var chartOverlayContent: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(createDragGesture(geometry: geometry))
        }
    }
    
    // Extract drag gesture creation to a separate method
    private func createDragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                handleDragChange(value: value, geometry: geometry)
            }
            .onEnded { _ in
                withAnimation(.easeOut(duration: 0.5)) {
                    selectedHour = nil
                }
            }
    }
    
    // Extract drag change handling to a separate method
    private func handleDragChange(value: DragGesture.Value, geometry: GeometryProxy) {
        let xPosition = value.location.x
        let relativeXPosition = xPosition / geometry.size.width
        let hourIndex = Int(relativeXPosition * CGFloat(hourlyData.count))
        
        if hourIndex >= 0 && hourIndex < hourlyData.count {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedHour = hourIndex
            }
        }
    }
}
