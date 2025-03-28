import UIKit
import FamilyControls
import SwiftUI

class MainViewController: UIViewController {
    
    // UI Elements
    private let statusLabel = UILabel()
    private let focusIndicator = FocusIndicatorView()
    private let scanButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNFC()
        
        // Request authorization when app launches
        Task {
            await AppBlockingManager.shared.requestAuthorization()
        }
    }
    
    private func setupUI() {
        // Set up the minimalist UI
        view.backgroundColor = Constants.Colors.background
        
        // Status Label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "TAP TO TOGGLE"
        statusLabel.textColor = Constants.Colors.text
        statusLabel.font = Constants.Fonts.title
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)
        
        // Focus Indicator
        focusIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(focusIndicator)
        
        // Scan Button
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.setTitle("SCAN NFC", for: .normal)
        scanButton.setTitleColor(Constants.Colors.text, for: .normal)
        scanButton.backgroundColor = Constants.Colors.background
        scanButton.layer.borderWidth = 1
        scanButton.layer.borderColor = Constants.Colors.text.cgColor
        scanButton.titleLabel?.font = Constants.Fonts.button
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        view.addSubview(scanButton)
        
        // Settings Button
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setTitle("SELECT APPS", for: .normal)
        settingsButton.setTitleColor(Constants.Colors.text, for: .normal)
        settingsButton.backgroundColor = Constants.Colors.background
        settingsButton.layer.borderWidth = 1
        settingsButton.layer.borderColor = Constants.Colors.text.cgColor
        settingsButton.titleLabel?.font = Constants.Fonts.button
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        view.addSubview(settingsButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            focusIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            focusIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            focusIndicator.widthAnchor.constraint(equalToConstant: 200),
            focusIndicator.heightAnchor.constraint(equalToConstant: 200),
            
            scanButton.topAnchor.constraint(equalTo: focusIndicator.bottomAnchor, constant: 40),
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.widthAnchor.constraint(equalToConstant: 200),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            
            settingsButton.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 20),
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 200),
            settingsButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        updateUI()
    }
    
    private func setupNFC() {
        NFCController.shared.onTagDetected = { [weak self] tagID in
            self?.handleTagDetection(tagID)
        }
    }
    
    private func handleTagDetection(_ tagID: String) {
        AppBlockingManager.shared.toggleFocusMode()
        updateUI()
    }
    
    private func updateUI() {
        let isActive = AppBlockingManager.shared.isFocusModeActive()
        focusIndicator.isActive = isActive
        statusLabel.text = isActive ? "FOCUS MODE ON" : "FOCUS MODE OFF"
    }
    
    @objc private func scanButtonTapped() {
        NFCController.shared.beginScanning()
    }
    
    @objc private func settingsButtonTapped() {
        Task {
            if let selection = await AppBlockingManager.shared.selectAppsToBlock() {
                // Present the activity selection view controller
                let activityVC = FamilyActivityPickerViewController(
                    selection: selection,
                    selectionMode: .apps
                )
                activityVC.delegate = self
                self.present(activityVC, animated: true)
            }
        }
    }
}

// MARK: - FamilyActivityPickerViewControllerDelegate
extension MainViewController: FamilyActivityPickerViewControllerDelegate {
    func familyActivityPickerViewControllerDidFinish(_ viewController: FamilyActivityPickerViewController) {
        viewController.dismiss(animated: true)
        
        // Get the selection and update the blocking manager
        let selection = viewController.selection
        AppBlockingManager.shared.setAppsToBlock(selection)
    }
    
    func familyActivityPickerViewControllerDidCancel(_ viewController: FamilyActivityPickerViewController) {
        viewController.dismiss(animated: true)
    }
}
