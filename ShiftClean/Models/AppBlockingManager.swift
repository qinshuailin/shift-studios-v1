import UIKit
import FamilyControls
import ManagedSettings

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

    func setAppsToBlock(_ selection: FamilyActivitySelection) {
        self.appsToBlock = selection.applicationTokens
    }

    func toggleFocusMode() {
        focusMode.toggle()

        if focusMode {
            // Enable blocking
            store.shield.applications = appsToBlock
            store.shield.applicationCategories = .all() // Optional: add if you want to block all categories
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
