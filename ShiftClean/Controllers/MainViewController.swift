import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings

class MainViewController: UIViewController {

    private let appBlockingModel = AppBlockingModel.shared
    private let toggleButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("MainViewController loaded")

        requestScreenTimePermission()
        view.backgroundColor = .white
        setupUI()
    }

    private func requestScreenTimePermission() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                print("✅ Screen Time authorization granted")
            } catch {
                print("❌ Screen Time authorization failed: \(error.localizedDescription)")
            }
        }
    }

    private func setupUI() {
        // Status Label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "FOCUS MODE OFF"
        statusLabel.textColor = .black
        statusLabel.font = UIFont.boldSystemFont(ofSize: 24)
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)

        // Toggle Button
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.setTitle("TOGGLE FOCUS MODE", for: .normal)
        toggleButton.setTitleColor(.white, for: .normal)
        toggleButton.backgroundColor = .systemBlue
        toggleButton.layer.cornerRadius = 8
        toggleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        toggleButton.addTarget(self, action: #selector(toggleFocusMode), for: .touchUpInside)
        view.addSubview(toggleButton)

        // Settings Button
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setTitle("SELECT APPS", for: .normal)
        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.backgroundColor = .systemGreen
        settingsButton.layer.cornerRadius = 8
        settingsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        view.addSubview(settingsButton)

        // Constraints
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            toggleButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toggleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toggleButton.widthAnchor.constraint(equalToConstant: 250),
            toggleButton.heightAnchor.constraint(equalToConstant: 50),

            settingsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 200),
            settingsButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func toggleFocusMode() {
        AppBlockingManager.shared.toggleFocusMode()
        let isActive = AppBlockingManager.shared.isFocusModeActive()
        statusLabel.text = isActive ? "FOCUS MODE ON" : "FOCUS MODE OFF"
    }

    @objc private func settingsButtonTapped() {
        let picker = FamilyActivityPicker(selection: Binding(
            get: { self.appBlockingModel.selection },
            set: {
                self.appBlockingModel.selection = $0
                AppBlockingManager.shared.setAppsToBlock($0)
            }
        ))

        let wrappedPicker = NavigationView {
            picker
                .navigationBarTitle("Select Apps", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    self.dismiss(animated: true)
                })
        }

        let controller = UIHostingController(rootView: wrappedPicker)
        present(controller, animated: true)
    }
}
