import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Set up MainViewController as root (removing tab bar)
        // let tabBarController = TabBarController() // <--- TEMPORARILY DISABLED
        // window?.rootViewController = tabBarController // <--- TEMPORARILY DISABLED
        
        // Use MainViewController directly as root
        let mainViewController = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)
        window?.rootViewController = navigationController
        
        // Make window visible
        window?.makeKeyAndVisible()
    }
}
