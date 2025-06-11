import UIKit

class TabBarController: UITabBarController {
    
    // MARK: - Properties
    private var floatingTabBar: FloatingTabBar!
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupFloatingTabBar()
        
        // Debug: Print to confirm TabBarController is loading
        print("TabBarController viewDidLoad called")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Hide the default tab bar
        tabBar.isHidden = true
        
        // Debug: Print to confirm tab bar state
        print("Default tab bar is hidden: \(tabBar.isHidden)")
        print("Floating tab bar frame: \(floatingTabBar.frame)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update floating tab bar position
        updateFloatingTabBarPosition()
    }
    
    // MARK: - Setup Methods
    private func setupViewControllers() {
        // Create view controllers for each tab
        let mainVC = MainViewController()
        let statsVC = StatsViewController()
        
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
    
    private func setupFloatingTabBar() {
        // Create floating tab bar
        floatingTabBar = FloatingTabBar(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        view.addSubview(floatingTabBar)
        
        // Configure tab items
        floatingTabBar.configure(with: [
            (title: "Focus", icon: "timer"),
            (title: "Stats", icon: "chart.bar")
        ]) { [weak self] index in
            self?.selectedIndex = index
        }
        
        // Set initial selection
        floatingTabBar.setSelectedIndex(selectedIndex)
        
        // Update position
        updateFloatingTabBarPosition()
    }
    
    private func updateFloatingTabBarPosition() {
        let tabBarHeight: CGFloat = 70
        let tabBarWidth: CGFloat = min(280, view.bounds.width - 40)
        let horizontalPadding: CGFloat = (view.bounds.width - tabBarWidth) / 2
        let bottomPadding: CGFloat = 30
        
        floatingTabBar.frame = CGRect(
            x: horizontalPadding,
            y: view.bounds.height - tabBarHeight - bottomPadding - view.safeAreaInsets.bottom,
            width: tabBarWidth,
            height: tabBarHeight
        )
    }
    
    // MARK: - Tab Bar Delegate
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        // This won't be called since we're hiding the default tab bar,
        // but keeping it for reference
        if let index = tabBar.items?.firstIndex(of: item) {
            floatingTabBar.setSelectedIndex(index)
        }
    }
}
