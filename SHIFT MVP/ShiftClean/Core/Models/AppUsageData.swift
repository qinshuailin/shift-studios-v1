import Foundation

struct AppUsageData: Identifiable, Equatable, Codable {
    let id: UUID
    let bundleID: String?
    let name: String
    let duration: TimeInterval
    let category: String
    let numberOfPickups: Int
    let numberOfNotifications: Int
    
    // Formatted duration string for display
    var durationString: String {
        return duration.formattedDuration()
    }
    
    init(bundleID: String? = nil, name: String, duration: TimeInterval, category: String = "Other", numberOfPickups: Int = 0, numberOfNotifications: Int = 0) {
        self.id = UUID()
        self.bundleID = bundleID
        self.name = name
        self.duration = duration
        self.category = category
        self.numberOfPickups = numberOfPickups
        self.numberOfNotifications = numberOfNotifications
    }
    
    static func == (lhs: AppUsageData, rhs: AppUsageData) -> Bool {
        return lhs.id == rhs.id
    }
}

extension TimeInterval {
    func formattedDuration() -> String {
        let duration = NSInteger(self)
        let numberOfHours = duration / 3600
        let numberOfMins = (duration % 3600) / 60
        var formatted = ""
        if numberOfHours == 0 {
            formatted = numberOfMins == 1 ? "1min" : "\(numberOfMins)mins"
        } else if numberOfHours == 1 {
            formatted = numberOfMins == 1 ? "1hr 1min" : "1hr \(numberOfMins)mins"
        } else {
            formatted = numberOfMins == 1 ? "\(numberOfHours)hrs 1min" : "\(numberOfHours)hrs \(numberOfMins)mins"
        }
        return formatted
    }
}
