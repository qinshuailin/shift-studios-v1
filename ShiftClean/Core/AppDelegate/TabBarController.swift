import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
        
        // Debug: Print to confirm TabBarController is loading
        print("TabBarController viewDidLoad called")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Debug: Print to confirm tab bar is visible
        print("Tab bar is hidden: \(tabBar.isHidden)")
        print("Tab bar frame: \(tabBar.frame)")
        
        // Force tab bar to be visible
        tabBar.isHidden = false
        tabBar.isTranslucent = true
    }
    
    private func setupTabBar() {
        // Set tab bar appearance for light theme
        tabBar.barTintColor = UIColor.white
        tabBar.tintColor = Constants.Colors.accent
        tabBar.unselectedItemTintColor = Constants.Colors.secondary
        
        // Ensure tab bar is visible
        tabBar.isHidden = false
        
        // Remove blur effect for clean white background
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        
        // Add subtle shadow instead of blur
        tabBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -1)
        tabBar.layer.shadowRadius = 4
        tabBar.layer.shadowOpacity = 0.5
    }
    
    private func setupViewControllers() {
        // Create view controllers for each tab
        let mainVC = MainViewController()
        let statsVC = StatsViewController()
        
        // Configure main tab
        mainVC.tabBarItem = UITabBarItem(
            title: "Focus",
            image: UIImage(systemName: "timer"),
            selectedImage: UIImage(systemName: "timer.fill")
        )
        
        // Configure stats tab
        statsVC.tabBarItem = UITabBarItem(
            title: "Stats",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )
        
        // Set view controllers - wrap in navigation controllers
        viewControllers = [
            UINavigationController(rootViewController: mainVC),
            UINavigationController(rootViewController: statsVC)
        ]
        
        // Set initial tab
        selectedIndex = 0
        
        // Debug: Print view controllers
        print("Tab bar view controllers: \(String(describing: viewControllers?.count))")
    }
}
