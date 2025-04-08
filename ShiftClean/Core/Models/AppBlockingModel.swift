import Foundation
import FamilyControls
import ManagedSettings

class AppBlockingModel {
    // Singleton instance that forwards to AppBlockingService
    static let shared = AppBlockingModel()
    
    // Reference to the actual service
    private let service = AppBlockingService.shared
    
    // Private initializer for singleton
    private init() {}
    
    // Forward all calls to AppBlockingService
    var selection: FamilyActivitySelection {
        get { return service.selection }
        set { service.selection = newValue }
    }
    
    func isFocusModeActive() -> Bool {
        return service.isFocusModeActive()
    }
    
    func toggleFocusMode() {
        service.toggleFocusMode()
    }
    
    func setAppsToBlock(_ selection: FamilyActivitySelection) {
        service.setAppsToBlock(selection)
    }
    
    func getSelectedApps() -> FamilyActivitySelection? {
        return service.getSelectedApps()
    }
}
