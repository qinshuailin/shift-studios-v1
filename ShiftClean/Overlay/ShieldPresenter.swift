import SwiftUI

class ShieldPresenter {
    static let shared = ShieldPresenter()
    private var window: UIWindow?

    func show(appName: String) {
        // If the overlay is already showing, do nothing.
        guard window == nil else { return }
        
        let shieldView = FocusShieldView(appName: appName)
        let hostingController = UIHostingController(rootView: shieldView)
        
        // Get the current window scene.
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let overlayWindow = UIWindow(windowScene: scene)
        overlayWindow.rootViewController = hostingController
        
        // Set a high window level so the overlay appears above everything.
        overlayWindow.windowLevel = .alert + 1
        overlayWindow.makeKeyAndVisible()
        
        window = overlayWindow
    }

    func hide() {
        window?.isHidden = true
        window = nil
    }
}
