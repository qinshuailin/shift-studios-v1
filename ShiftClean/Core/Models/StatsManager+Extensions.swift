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
        // For demo purposes, return a simulated value
        // In a real app, this would calculate from actual usage data
        return Int.random(in: 60...120) // Random value between 1h and 2h
    }
}
