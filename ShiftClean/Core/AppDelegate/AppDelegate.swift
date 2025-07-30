import UIKit
import FamilyControls
import DeviceActivity

extension DeviceActivityName {
    static let daily = Self("daily")
    static let totalActivity = Self("Total Activity")
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Initialize haptic system for instant response
        Constants.Haptics.initialize()
        print("[AppDelegate] Haptics initialized")
        

        // Request FamilyControls authorization using .individual (Apple methodology)
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                print("[AppDelegate] FamilyControls authorized")
            } catch {
                print("[AppDelegate] FamilyControls error: \(error)")
            }
        }
        
        // Request authorization for device activity tracking
        Task {
            let granted = await DeviceActivityManager.shared.requestAuthorization()
            if granted {
                DeviceActivityManager.shared.scheduleUsageTracking()
                // Initialize MyModel monitoring for device activity
                MyModel.shared.initiateMonitoring()
                // CRITICAL: Clear any problematic system restrictions
                MyModel.shared.clearAllSystemRestrictions()
                print("[AppDelegate] Device activity initialized")
            }
        }
        scheduleDeviceActivityReport() // Schedule device activity monitoring on launch
        
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

    // MARK: - Device Activity Scheduling
    func scheduleDeviceActivityReport() {
        let center = DeviceActivityCenter()
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        do {
            try center.startMonitoring(.totalActivity, during: schedule)
            print("Device activity monitoring started.")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Request background time to keep Live Activity timer running
        if StatsManager.shared.isFocusModeActive {
            let taskId = application.beginBackgroundTask(withName: "LiveActivityUpdate") {
                // End the task if time expires
                application.endBackgroundTask(UIBackgroundTaskIdentifier.invalid)
            }
            // Sync Live Activity one more time
            StatsManager.shared.syncLiveActivityIfNeeded()
            // End the background task after sync
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                application.endBackgroundTask(taskId)
            }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Warm up haptic generators when app becomes active for instant response
        Constants.Haptics.initialize()
        

    }
}
