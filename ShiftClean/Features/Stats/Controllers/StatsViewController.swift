import UIKit
import SwiftUI

class StatsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar on this screen
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show navigation bar on other screens
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupUI() {
        // Get data from StatsManager
        let screenTime = StatsManager.shared.totalFocusTime
        let timeSaved = StatsManager.shared.totalTimeSavedToday
        let dailyGoal = StatsManager.shared.dailyGoal
        let streak = StatsManager.shared.currentStreak
        let weeklyData = StatsManager.shared.weeklyData
        
        // Create the SwiftUI view
        let statsView = UIHostingController(rootView: StatsView(
            screenTime: screenTime,
            timeSaved: timeSaved,
            dailyGoal: dailyGoal,
            streak: streak,
            weeklyData: weeklyData
        ))
        
        // Add as child view controller
        addChild(statsView)
        view.addSubview(statsView.view)
        
        // Configure constraints
        statsView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsView.view.topAnchor.constraint(equalTo: view.topAnchor),
            statsView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statsView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statsView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        statsView.didMove(toParent: self)
    }
}
