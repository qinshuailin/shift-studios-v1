import Foundation
import ManagedSettings
import FamilyControls

class AppBlockingManager {
    static let shared = AppBlockingManager()

    private let store = ManagedSettingsStore()
    private var currentTokens = Set<ApplicationToken>()
    private var focusModeActive = false

    func setAppsToBlock(_ selection: FamilyActivitySelection) {
        currentTokens = selection.applicationTokens
        if focusModeActive {
            store.shield.applications = currentTokens.isEmpty ? nil : currentTokens
        }
    }

    func toggleFocusMode() {
        focusModeActive.toggle()
        store.shield.applications = focusModeActive && !currentTokens.isEmpty ? currentTokens : nil
    }

    func isFocusModeActive() -> Bool {
        return focusModeActive
    }

    func resetAllBlocking() {
        store.shield.applications = nil
        currentTokens.removeAll()
        focusModeActive = false
    }
}
