import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine
import UIKit

class AppBlockingService: ObservableObject {
    // MARK: - Singleton
    static let shared = AppBlockingService()
    
    // MARK: - Properties
    private let store = ManagedSettingsStore()
    private let userDefaults = UserDefaults.standard
    private let focusModeKey = "focusModeActive"
    private let selectedAppsKey = "selectedApps"
    
    // Published property for SwiftUI integration
    @Published var selection = FamilyActivitySelection()
    
    // MARK: - Initialization
    private init() {
        // Load saved selection if available
        if let savedSelection = getSelectedApps() {
            self.selection = savedSelection
        }
        
        // CRITICAL: Restore app blocking state if focus mode was active
        if isFocusModeActive() {
            print("[AppBlockingService] Restoring app blocking state - focus mode was active")
            if let savedSelection = getSelectedApps() {
                applyAppRestrictions(savedSelection)
                print("[AppBlockingService] Restored blocking for \(savedSelection.applicationTokens.count) apps")
            } else {
                print("[AppBlockingService] Focus mode active but no apps selected")
            }
        } else {
            print("[AppBlockingService] Focus mode inactive, no blocking to restore")
        }
    }
    
    // MARK: - Public Methods
    
    /// Checks if focus mode is currently active
    func isFocusModeActive() -> Bool {
        return UserDefaults.standard.bool(forKey: "focusModeActive")
    }
    
    /// Toggles focus mode on/off and updates statistics
    func toggleFocusMode() {
        let isCurrentlyActive = isFocusModeActive()
        if isCurrentlyActive {
            // Turn off focus mode
            disableFocusMode()
            StatsManager.shared.endFocusSession()
        } else {
            // Turn on focus mode
            enableFocusMode()
            StatsManager.shared.startFocusSession()
        }
        // Single notification
        NotificationCenter.default.post(name: NSNotification.Name(Constants.Notifications.focusModeToggled), object: nil)
    }
    
    /// Activates focus mode directly
    func activateFocusMode() {
        if !isFocusModeActive() {
            enableFocusMode()
            StatsManager.shared.startFocusSession()
            // Provide haptic feedback for focus activation
            Constants.Haptics.focusActivated()
            // Fixed post method call
            NotificationCenter.default.post(name: NSNotification.Name(Constants.Notifications.focusModeToggled), object: nil)
        }
    }
    
    /// Deactivates focus mode directly
    func deactivateFocusMode() {
        if isFocusModeActive() {
            disableFocusMode()
            StatsManager.shared.endFocusSession()
            // Provide haptic feedback for focus deactivation
            Constants.Haptics.focusDeactivated()
            // Fixed post method call
            NotificationCenter.default.post(name: NSNotification.Name(Constants.Notifications.focusModeToggled), object: nil)
        }
    }
    
    /// Sets the apps to block and saves the selection
    func setAppsToBlock(_ newSelection: FamilyActivitySelection) {
        // Update the published property
        selection = newSelection
        
        // Save the selection using simple UserDefaults
        if let encodedData = try? JSONEncoder().encode(newSelection) {
            UserDefaults.standard.set(encodedData, forKey: selectedAppsKey)
        }
        
        // If focus mode is active, update the blocked apps
        if isFocusModeActive() {
            applyAppRestrictions(newSelection)
        }
    }
    
    /// Retrieves the currently selected apps to block
    func getSelectedApps() -> FamilyActivitySelection? {
        guard let data = UserDefaults.standard.data(forKey: selectedAppsKey) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
    
    // MARK: - Private Methods
    
    private func enableFocusMode() {
        UserDefaults.standard.set(true, forKey: focusModeKey)
        // Apply app restrictions if apps are selected
        if let selection = getSelectedApps() {
            applyAppRestrictions(selection)
        }
    }
    
    // Made public for state synchronization
    func disableFocusMode() {
        UserDefaults.standard.set(false, forKey: focusModeKey)
        // Remove all app restrictions
        store.shield.applications = nil
    }
    
    private func applyAppRestrictions(_ selection: FamilyActivitySelection) {
        // Set the selected applications to be shielded
        print("[AppBlockingService] Applying shield to \(selection.applicationTokens.count) apps")
        store.shield.applications = selection.applicationTokens
    }
}
