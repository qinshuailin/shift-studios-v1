import Foundation

struct FocusSession: Codable, Identifiable {
    let id = UUID()
    let startTime: Date
    var endTime: Date?
    var durationInMinutes: Int? {
        guard let endTime = endTime else { return nil }
        return Int(endTime.timeIntervalSince(startTime) / 60)
    }
    var isActive: Bool {
        return endTime == nil
    }
}
