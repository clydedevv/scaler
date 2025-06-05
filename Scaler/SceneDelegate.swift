import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: ShakeDetectingWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create the custom shake-detecting window
        window = ShakeDetectingWindow(windowScene: windowScene)
        
        // Create the SwiftUI content view with environment objects
        let pitchGateModel = PitchGateModel()
        let shakeSprintController = ShakeSprintController()
        let usageTimer = UsageTimer()
        
        let contentView = ContentView()
            .environmentObject(pitchGateModel)
            .environmentObject(shakeSprintController)
            .environmentObject(usageTimer)
        
        // Set up the window
        window?.rootViewController = UIHostingController(rootView: contentView)
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }
} 