import Foundation

struct CategoryUsageData: Identifiable {
    let id = UUID()
    let category: String
    let apps: [AppUsageData]
    // Optional: Add a token for category icon support in the future
    let token: String? = nil
    
    var totalTime: TimeInterval {
        return apps.reduce(0) { $0 + $1.duration }
    }
    
    init(category: String, apps: [AppUsageData]) {
        self.category = category
        self.apps = apps
    }
}
