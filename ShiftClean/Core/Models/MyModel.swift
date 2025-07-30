import SwiftUI
import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

class MyModel: ObservableObject {
    static let shared = MyModel()
    let store = ManagedSettingsStore()
    
    private init() {
        // Load saved selection from AppBlockingService if available
        if let savedSelection = AppBlockingService.shared.getSelectedApps() {
            // Set directly to avoid triggering willSet during initialization
            _selectionToDiscourage = Published(initialValue: savedSelection)
        }
    }
    
    @Published var selectionToDiscourage = FamilyActivitySelection() {
        willSet {
            print("[MyModel] New selection: \(newValue.applicationTokens.count) apps")
            // Save selection to AppBlockingService instead of managing shield directly
            AppBlockingService.shared.setAppsToBlock(newValue)
        }
    }
    
    func initiateMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true,
            warningTime: nil
        )
        let center = DeviceActivityCenter()
        do {
            try center.startMonitoring(.daily, during: schedule)
            print("[MyModel] DeviceActivity monitoring scheduled")
        } catch {
            print("[MyModel] Could not start monitoring: \(error)")
        }
        // REMOVED: All problematic system-wide restrictions that were hiding apps
        // Only monitoring is needed for usage tracking
    }
    
    // CRITICAL: Method to clear all problematic restrictions
    func clearAllSystemRestrictions() {
        print("[MyModel] Clearing system restrictions")
        store.dateAndTime.requireAutomaticDateAndTime = false
        store.account.lockAccounts = false
        store.passcode.lockPasscode = false
        store.siri.denySiri = false
        store.appStore.denyInAppPurchases = false
        store.appStore.maximumRating = 1000 // Set to high value to allow all apps
        store.appStore.requirePasswordForPurchases = false
        store.media.denyExplicitContent = false
        store.gameCenter.denyMultiplayerGaming = false
        store.media.denyMusicService = false
        print("[MyModel] System restrictions cleared")
    }
} 