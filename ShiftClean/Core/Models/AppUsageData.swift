import Foundation

struct AppUsageData: Identifiable, Equatable {
    let id = UUID()
    let bundleID: String?
    let name: String
    let timeSaved: TimeInterval
    let category: String
    let numberOfPickups: Int
    let numberOfNotifications: Int
    
    init(bundleID: String? = nil, name: String, timeSaved: TimeInterval, category: String = "Other", numberOfPickups: Int = 0, numberOfNotifications: Int = 0) {
        self.bundleID = bundleID
        self.name = name
        self.timeSaved = timeSaved
        self.category = category
        self.numberOfPickups = numberOfPickups
        self.numberOfNotifications = numberOfNotifications
    }
    
    static func == (lhs: AppUsageData, rhs: AppUsageData) -> Bool {
        return lhs.id == rhs.id
    }
}
