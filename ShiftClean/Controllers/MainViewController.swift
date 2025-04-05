import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings

class MainViewController: UIViewController {
    private let appBlockingModel = AppBlockingModel.shared
    private let toggleButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let nfcButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        requestScreenTimePermission()
        view.backgroundColor = .white
        setupUI()
        NFCController.shared.delegate = self
    }

    private func requestScreenTimePermission() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                print("Screen Time authorization granted")
            } catch {
                print("Authorization failed: \(error.localizedDescription)")
            }
        }
    }

    private func setupUI() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "FOCUS MODE OFF"
        statusLabel.textColor = .black
        statusLabel.font = UIFont.boldSystemFont(ofSize: 24)
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)

        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.setTitle("TOGGLE FOCUS MODE", for: .normal)
        toggleButton.setTitleColor(.white, for: .normal)
        toggleButton.backgroundColor = .systemBlue
        toggleButton.layer.cornerRadius = 8
        toggleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        toggleButton.addTarget(self, action: #selector(toggleFocusMode), for: .touchUpInside)
        view.addSubview(toggleButton)

        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setTitle("SELECT APPS", for: .normal)
        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.backgroundColor = .systemGreen
        settingsButton.layer.cornerRadius = 8
        settingsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        view.addSubview(settingsButton)

        nfcButton.translatesAutoresizingMaskIntoConstraints = false
        nfcButton.setTitle("TAP SHIFT TAG", for: .normal)
        nfcButton.setTitleColor(.white, for: .normal)
        nfcButton.backgroundColor = .systemOrange
        nfcButton.layer.cornerRadius = 8
        nfcButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        nfcButton.addTarget(self, action: #selector(scanNFC), for: .touchUpInside)
        view.addSubview(nfcButton)

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
            settingsButton.heightAnchor.constraint(equalToConstant: 50),

            nfcButton.bottomAnchor.constraint(equalTo: settingsButton.topAnchor, constant: -20),
            nfcButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nfcButton.widthAnchor.constraint(equalToConstant: 200),
            nfcButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func toggleFocusMode() {
        AppBlockingManager.shared.toggleFocusMode()
        updateStatusLabel()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    @objc private func settingsButtonTapped() {
        let picker = FamilyActivityPicker(selection: Binding(
            get: { self.appBlockingModel.selection },
            set: {
                self.appBlockingModel.selection = $0
                AppBlockingManager.shared.setAppsToBlock($0)
            }
        ))
        .navigationTitle("Choose Activities")
        .navigationBarTitleDisplayMode(.inline)

        let wrapped = NavigationView {
            picker
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            self.dismiss(animated: true)
                        }
                        .foregroundColor(.white)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            self.dismiss(animated: true)
                        }
                        .foregroundColor(.white)
                    }
                }
        }

        let controller = UIHostingController(rootView: wrapped)
        controller.overrideUserInterfaceStyle = .dark
        present(controller, animated: true)
    }

    @objc private func scanNFC() {
        NFCController.shared.beginScanning()
    }

    private func updateStatusLabel() {
        let isActive = AppBlockingManager.shared.isFocusModeActive()
        statusLabel.text = isActive ? "FOCUS MODE ON" : "FOCUS MODE OFF"
    }
}

extension MainViewController: NFCControllerDelegate {
    func didScanNFCTag() {
        AppBlockingManager.shared.toggleFocusMode()
        updateStatusLabel()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func didToggleFocusMode() {
        updateStatusLabel()
    }
}
