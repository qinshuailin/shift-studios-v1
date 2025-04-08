import Foundation

struct CategoryUsageData: Identifiable {
    let id = UUID()
    let category: String
    let apps: [AppUsageData]
    
    var totalTime: TimeInterval {
        return apps.reduce(0) { $0 + $1.timeSaved }
    }
    
    init(category: String, apps: [AppUsageData]) {
        self.category = category
        self.apps = apps
    }
}
