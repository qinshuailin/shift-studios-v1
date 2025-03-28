import UIKit
import FamilyControls
import ManagedSettings
import DeviceActivity

class AppBlockingManager {
    static let shared = AppBlockingManager()
    
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private var focusMode = false
    
    // Apps to block when in focus mode
    private var appsToBlock = Set<ApplicationToken>()
    
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            print("Authorization successful")
        } catch {
            print("Failed to authorize: \(error.localizedDescription)")
        }
    }
    
    func selectAppsToBlock() async -> FamilyActivitySelection? {
        let selection = FamilyActivitySelection()
        return selection
    }
    
    func setAppsToBlock(_ selection: FamilyActivitySelection) {
        self.appsToBlock = selection.applicationTokens
    }
    
    func toggleFocusMode() {
        focusMode.toggle()
        
        if focusMode {
            // Enable blocking
            let model = BlockingModel()
            model.applicationTokens = appsToBlock
            store.shield.applications = model
            
            // Show blocking UI
            store.shield.applicationCategories = .all()
        } else {
            // Disable blocking
            store.shield.applications = nil
            store.shield.applicationCategories = nil
        }
    }
    
    func isFocusModeActive() -> Bool {
        return focusMode
    }
}
