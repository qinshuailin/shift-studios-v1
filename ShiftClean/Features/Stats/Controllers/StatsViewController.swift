import UIKit
import SwiftUI

class StatsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Create the SwiftUI view
        let statsView = UIHostingController(rootView: DropdownStatsView(
            focusTime: StatsManager.shared.totalFocusTime,
            streak: StatsManager.shared.currentStreak,
            appUsageData: StatsManager.shared.appUsageData,
            weeklyData: StatsManager.shared.weeklyData,
            categoryData: StatsManager.shared.categoryUsageData,
            pickupsData: StatsManager.shared.pickupsData,
            hourlyUsageData: StatsManager.shared.hourlyUsageData,
            firstPickupTime: StatsManager.shared.firstPickupTime,
            longestSession: StatsManager.shared.longestSession
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
