import Foundation
import ManagedSettings
import FamilyControls

class AppBlockingManager {
    static let shared = AppBlockingManager()

    private let store = ManagedSettingsStore()
    private var currentTokens = Set<ApplicationToken>()
    private var focusModeActive = false

    // In-memory counter for the current session
    private(set) var sessionBlockCount: Int = 0
    // Captured count at the end of the session (for the popup)
    private(set) var lastSessionBlockCount: Int = 0

    func setAppsToBlock(_ selection: FamilyActivitySelection) {
        currentTokens = selection.applicationTokens
        if focusModeActive {
            store.shield.applications = currentTokens.isEmpty ? nil : currentTokens
        }
    }

    func toggleFocusMode() {
        focusModeActive.toggle()

        if focusModeActive {
            // Start a new session: reset counter
            sessionBlockCount = 0
            // Apply blocking with a slight delay
            store.shield.applications = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.store.shield.applications = self.currentTokens.isEmpty ? nil : self.currentTokens
            }
        } else {
            // End session: capture final count
            lastSessionBlockCount = sessionBlockCount
            store.shield.applications = nil
            // Reset session counter for next session
            sessionBlockCount = 0
        }
    }

    func isFocusModeActive() -> Bool {
        return focusModeActive
    }

    // Call this each time a blocked app is attempted (from your NFC or other triggers)
    func incrementBlockCount() {
        guard focusModeActive else { return }
        sessionBlockCount += 1
        print("Incremented sessionBlockCount to \(sessionBlockCount)")
    }

    func getLastSessionCount() -> Int {
        return lastSessionBlockCount
    }

    func resetAllBlocking() {
        store.shield.applications = nil
        currentTokens.removeAll()
        focusModeActive = false
        sessionBlockCount = 0
        lastSessionBlockCount = 0
    }
}
