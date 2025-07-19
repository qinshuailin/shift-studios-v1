import Foundation

extension StatsManager {
    // Add a property for daily goal
    var dailyGoal: Int {
        get {
            return UserDefaults.standard.integer(forKey: "dailyGoal") == 0 ? 120 : UserDefaults.standard.integer(forKey: "dailyGoal")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "dailyGoal")
        }
    }
    
    // Add a method to update daily goal
    func updateDailyGoal(_ newGoal: Int) {
        dailyGoal = newGoal
    }
    
    // Add a property for total time saved today
    var totalTimeSavedToday: Int {
        // Calculate from actual usage data
        // Example: sum focus minutes for today
        return totalFocusTime
    }
}
