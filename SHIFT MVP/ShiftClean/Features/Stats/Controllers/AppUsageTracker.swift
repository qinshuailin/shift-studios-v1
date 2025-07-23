import Foundation

/**
 * AppUsageTracker
 * 
 * Tracks app usage and blocked time for applications.
 */
class AppUsageTracker {
    static let shared = AppUsageTracker()

    private var blockStartTimes: [String: Date] = [:]
    private var totalBlockedTime: [String: TimeInterval] = [:]

    func trackBlockedAccess(for bundleID: String) {
        if blockStartTimes[bundleID] == nil {
            blockStartTimes[bundleID] = Date()
        }
    }

    func updateBlockEnd(for bundleID: String) {
        guard let start = blockStartTimes[bundleID] else { return }
        let duration = Date().timeIntervalSince(start)
        totalBlockedTime[bundleID, default: 0] += duration
        blockStartTimes.removeValue(forKey: bundleID)
    }

    func endAllBlocks() {
        for bundleID in blockStartTimes.keys {
            updateBlockEnd(for: bundleID)
        }
    }

    func getBlockedDurations() -> [AppUsageData] {
        return totalBlockedTime.map { (bundleID, time) in
            AppUsageData(bundleID: bundleID, name: extractName(from: bundleID), duration: time)
        }
    }

    func reset() {
        totalBlockedTime.removeAll()
        blockStartTimes.removeAll()
    }

    private func extractName(from bundleID: String) -> String {
        let components = bundleID.components(separatedBy: ".")
        return components.last?.capitalized ?? bundleID
    }
}
