import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func sceneDidBecomeActive(_ scene: UIScene) {
        if AppBlockingManager.shared.isFocusModeActive() {
            ShieldPresenter.shared.show(appName: "Blocked App")
        } else {
            ShieldPresenter.shared.hide()
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()
    }
}
