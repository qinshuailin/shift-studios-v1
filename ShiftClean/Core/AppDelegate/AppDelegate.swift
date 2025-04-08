import UIKit
import FamilyControls
import DeviceActivity

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Request authorization for device activity tracking
        requestDeviceActivityAuthorization()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - Device Activity Authorization
    
    func requestDeviceActivityAuthorization() {
        Task {
            // Remove the do-catch block since requestAuthorization() doesn't throw
            let authorized = await DeviceActivityManager.shared.requestAuthorization()
            
            if authorized {
                print("Device activity authorization granted")
                
                // Start fetching activity data in the background
                Task {
                    let _ = await DeviceActivityManager.shared.fetchActivityData()
                }
            } else {
                print("Device activity authorization denied")
            }
        }
    }
    
    // MARK: - App Termination
    
    func applicationWillTerminate(_ application: UIApplication) {
        // End all tracking when app terminates
        AppUsageTracker.shared.endAllBlocks()
        
        // Save any pending stats
        if StatsManager.shared.isFocusModeActive {
            StatsManager.shared.endFocusSession()
        }
    }
}
