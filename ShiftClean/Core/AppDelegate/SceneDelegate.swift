import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Set up tab bar controller as root
        let tabBarController = TabBarController()
        window?.rootViewController = tabBarController
        
        // Make window visible
        window?.makeKeyAndVisible()
    }
}
