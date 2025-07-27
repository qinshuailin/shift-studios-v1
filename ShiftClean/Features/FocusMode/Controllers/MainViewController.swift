import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings
import CoreNFC

// Add a SwiftUI wrapper for the picker with Cancel/Done
struct ActivityPickerSheet: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationBarTitle("Choose Activities", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    },
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
        }
    }
}

class MainViewController: UIViewController {

    // MARK: - Properties
    private var hostingController: UIHostingController<HomeView>?
    private var statsObserver: NSObjectProtocol?
    private let nfcController = NFCController.shared
    private let model = MyModel.shared

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let homeView = HomeView()
        let hostingController = UIHostingController(rootView: homeView)
        self.hostingController = hostingController
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
        nfcController.delegate = self
        setupStatsObserver()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar on this screen
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Ensure tab bar is visible
        // tabBarController?.tabBar.isHidden = false // <--- TEMPORARILY DISABLED
        
        // Update UI based on current state
        // Ensure time saved display is up to date when app enters foreground
        StatsManager.shared.updateTotalTimeSavedToday()
        // Sync Live Activity with actual elapsed time
        StatsManager.shared.syncLiveActivityIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show navigation bar on other screens
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Move the stack view up so it sits in the top 2/3 of the screen
    }
    
    // MARK: - Helper Methods
    private func setupStatsObserver() {
        // Remove any existing observer
        if let observer = statsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        // Observe changes to stats
        statsObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StatsUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // You can update SwiftUI view via ObservableObject if needed
        }
    }
    
    @objc private func appDidEnterBackground() {
        // Ensure live activity gets one final update before backgrounding
        if AppBlockingService.shared.isFocusModeActive() {
            StatsManager.shared.updateTotalTimeSavedToday()
            StatsManager.shared.syncLiveActivityIfNeeded()
        }
    }

    @objc private func appWillEnterForeground() {
        print("[MainViewController] 🌟 App entering foreground - BULLETPROOF RESTART")
        
        // Refresh everything when returning to foreground
        StatsManager.shared.updateTotalTimeSavedToday()
        StatsManager.shared.syncLiveActivityIfNeeded()
        
        // BULLETPROOF: If focus mode is active, aggressively restart timers
        if StatsManager.shared.isFocusModeActive {
            print("[MainViewController] 🔥 Focus mode active - forcing timer restart")
            // Force restart the Live Activity timer
            StatsManager.shared.startLiveActivityTimer()
        }
        
        // If you need to update SwiftUI, use ObservableObject
    }
    
    // Clean up observer when view controller is deallocated
    deinit {
        if let observer = statsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - GoalEditorDelegate
extension MainViewController: GoalEditorDelegate {
    func goalEditor(_ editor: GoalEditorViewController, didSetGoal goalMinutes: Int) {
        UserDefaults.standard.set(goalMinutes, forKey: "dailyGoalMinutes")
        // If you need to update SwiftUI, use ObservableObject
    }
}

// MARK: - NFCControllerDelegate
extension MainViewController: NFCControllerDelegate {
    func didScanNFCTag() {}
    func didToggleFocusMode() {}
    func didDetectTagWithID(tagID: String) {}
}

// MARK: - UIView Extension
extension UIView {
    func pinEdgesToSuperview() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
    }
}
