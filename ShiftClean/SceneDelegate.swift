import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        // Force dark mode at the system level
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .dark
        }
        
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // intentionally left blank, no custom shield presenter calls
    }
}
