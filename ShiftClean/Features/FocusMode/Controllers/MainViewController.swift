import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings
import CoreNFC

class MainViewController: UIViewController {

    // MARK: - Properties
    private let statusLabel = UILabel()
    private let nfcButton = UIButton()
    private let appSelectionButton = UIButton()
    private var familyActivitySelection = FamilyActivitySelection()
    private let nfcController = NFCController.shared
    
    // Haptic feedback generators
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        nfcController.delegate = self
        
        // Prepare haptic feedback generators
        selectionFeedback.prepare()
        impactFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar on this screen
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Ensure tab bar is visible
        tabBarController?.tabBar.isHidden = false
        
        // Animate content appearance
        animateContentAppearance()
        
        // Update UI based on current state
        updateStatusLabel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show navigation bar on other screens
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Set background color
        view.backgroundColor = Constants.Colors.background
        
        // Setup status label
        setupStatusLabel()
        
        // Setup NFC button
        setupNFCButton()
        
        // Setup app selection button
        setupAppSelectionButton()
    }
    
    private func setupStatusLabel() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "FOCUS MODE OFF"
        statusLabel.textAlignment = .center
        statusLabel.textColor = Constants.Colors.text
        statusLabel.font = Constants.Fonts.title
        statusLabel.alpha = 0 // Start invisible for animation
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50)
        ])
    }
    
    private func setupNFCButton() {
        nfcButton.translatesAutoresizingMaskIntoConstraints = false
        nfcButton.setTitle("SCAN NFC TAG", for: .normal)
        nfcButton.setTitleColor(.white, for: .normal)
        nfcButton.titleLabel?.font = Constants.Fonts.button
        
        // Create gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        gradientLayer.cornerRadius = 25
        gradientLayer.colors = [
            UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.0, green: 0.3, blue: 0.8, alpha: 1.0).cgColor
        ]
        
        // Create a UIImage from the gradient layer
        UIGraphicsBeginImageContextWithOptions(gradientLayer.frame.size, false, 0)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Set the gradient image as background
        nfcButton.setBackgroundImage(gradientImage, for: .normal)
        
        nfcButton.layer.cornerRadius = 25
        nfcButton.clipsToBounds = true
        nfcButton.layer.shadowColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.5).cgColor
        nfcButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        nfcButton.layer.shadowRadius = 8
        nfcButton.layer.shadowOpacity = 0.5
        nfcButton.layer.masksToBounds = false
        
        nfcButton.addTarget(self, action: #selector(nfcButtonTapped), for: .touchUpInside)
        nfcButton.alpha = 0 // Start invisible for animation
        view.addSubview(nfcButton)
        
        NSLayoutConstraint.activate([
            nfcButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nfcButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 30),
            nfcButton.widthAnchor.constraint(equalToConstant: 200),
            nfcButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add touch animations
        addButtonTouchAnimations(to: nfcButton)
    }
    
    private func setupAppSelectionButton() {
        appSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        appSelectionButton.setTitle("SELECT APPS", for: .normal)
        appSelectionButton.setTitleColor(Constants.Colors.background, for: .normal)
        appSelectionButton.titleLabel?.font = Constants.Fonts.button
        appSelectionButton.backgroundColor = Constants.Colors.accent
        appSelectionButton.layer.cornerRadius = 20
        appSelectionButton.layer.borderWidth = 1
        appSelectionButton.layer.borderColor = Constants.Colors.accent.cgColor
        appSelectionButton.addTarget(self, action: #selector(appSelectionButtonTapped), for: .touchUpInside)
        appSelectionButton.alpha = 0 // Start invisible for animation
        view.addSubview(appSelectionButton)
        
        NSLayoutConstraint.activate([
            appSelectionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appSelectionButton.topAnchor.constraint(equalTo: nfcButton.bottomAnchor, constant: 20),
            appSelectionButton.widthAnchor.constraint(equalToConstant: 160),
            appSelectionButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Add touch animations
        addButtonTouchAnimations(to: appSelectionButton)
    }
    
    private func addButtonTouchAnimations(to button: UIButton) {
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    // MARK: - Button Touch Animations
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        
        // Light haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform.identity
        }
    }
    
    // MARK: - Animation Methods
    private func animateContentAppearance() {
        // Reset alpha values
        statusLabel.alpha = 0
        nfcButton.alpha = 0
        appSelectionButton.alpha = 0
        
        // Animate each element with a delay
        UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
            self.statusLabel.alpha = 1
        })
        
        UIView.animate(withDuration: 0.6, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.nfcButton.alpha = 1
            self.nfcButton.transform = CGAffineTransform.identity
        })
        
        UIView.animate(withDuration: 0.5, delay: 0.7, options: [], animations: {
            self.appSelectionButton.alpha = 1
        })
    }
    
    // MARK: - Action Methods
    @objc private func nfcButtonTapped() {
        // Provide haptic feedback
        impactFeedback.impactOccurred(intensity: 0.8)
        
        // Begin NFC scanning
        nfcController.beginScanning()
        
        // Create ripple effect from the center
        createRippleEffect(from: nfcButton.center)
    }
    
    @objc private func appSelectionButtonTapped() {
        // Provide haptic feedback
        selectionFeedback.selectionChanged()
        
        // Create a binding for the selection
        let selection = FamilyActivitySelection()
        familyActivitySelection = selection
        
        // Create a simple SwiftUI view for app selection
        let pickerView = FamilyActivityPicker(selection: Binding<FamilyActivitySelection>(
            get: { self.familyActivitySelection },
            set: { self.familyActivitySelection = $0 }
        ))
        
        // Wrap in a navigation view with done button
        let contentView = NavigationView {
            pickerView
                .navigationBarTitle("Select Apps", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    self.dismiss(animated: true) {
                        // Update the app blocking service with the selected apps
                        AppBlockingService.shared.setAppsToBlock(self.familyActivitySelection)
                        
                        // Provide success haptic feedback
                        self.notificationFeedback.notificationOccurred(.success)
                    }
                })
        }
        .environment(\.colorScheme, .light) // Changed to light mode
        
        let controller = UIHostingController(rootView: contentView)
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    // MARK: - Helper Methods
    private func updateStatusLabel() {
        let isActive = AppBlockingService.shared.isFocusModeActive()
        let oldText = statusLabel.text
        let newText = isActive ? "FOCUS MODE ON" : "FOCUS MODE OFF"
        
        // Only animate if text is changing
        if oldText != newText {
            // Animate text change with fade and scale
            UIView.transition(with: statusLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.statusLabel.text = newText
                
                // Change color based on state
                if isActive {
                    self.statusLabel.textColor = UIColor.systemGreen
                } else {
                    self.statusLabel.textColor = Constants.Colors.text
                }
            })
            
            // Provide haptic feedback
            notificationFeedback.notificationOccurred(isActive ? UINotificationFeedbackGenerator.FeedbackType.success : UINotificationFeedbackGenerator.FeedbackType.warning)
        }
    }
    
    private func createRippleEffect(from center: CGPoint) {
        let rippleView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        rippleView.center = center
        rippleView.backgroundColor = Constants.Colors.accent
        rippleView.layer.cornerRadius = 10
        rippleView.alpha = 0.8
        view.insertSubview(rippleView, belowSubview: nfcButton)
        
        UIView.animate(withDuration: 1.0, animations: {
            rippleView.transform = CGAffineTransform(scaleX: 30, y: 30)
            rippleView.alpha = 0
        }, completion: { _ in
            rippleView.removeFromSuperview()
        })
    }
}

// MARK: - NFCControllerDelegate
extension MainViewController: NFCControllerDelegate {
    func didScanNFCTag() {
        // Handle NFC tag scan
        // Update UI or provide feedback as needed
        updateStatusLabel()
    }
    
    func didToggleFocusMode() {
        // Handle focus mode toggle
        let isActive = AppBlockingService.shared.isFocusModeActive()
        
        if isActive {
            // Focus mode was activated
            // Start focus session in stats manager
            StatsManager.shared.startFocusSession()
            
            // Show success notification
            showNotification(message: "Focus mode activated", type: .success)
        } else {
            // Focus mode was deactivated
            // End focus session in stats manager
            StatsManager.shared.endFocusSession()
            
            // Show success notification
            showNotification(message: "Focus mode deactivated", type: .success)
        }
        
        // Update UI
        updateStatusLabel()
    }
    
    func didDetectTagWithID(tagID: String) {
        // Handle specific tag ID detection
        print("Detected tag with ID: \(tagID)")
    }
    
    private func showNotification(message: String, type: NotificationType) {
        let notification = NotificationView(message: message, type: type)
        let hostingController = UIHostingController(rootView: notification)
        hostingController.view.backgroundColor = .clear
        
        // Add as child view controller
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            hostingController.view.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        hostingController.didMove(toParent: self)
        
        // Provide haptic feedback based on notification type
        switch type {
        case .success:
            notificationFeedback.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.success)
        case .warning:
            notificationFeedback.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.warning)
        case .error:
            notificationFeedback.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.error)
        }
        
        // Animate in
        hostingController.view.transform = CGAffineTransform(translationX: 0, y: 100)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            hostingController.view.transform = .identity
        })
        
        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.5, animations: {
                hostingController.view.transform = CGAffineTransform(translationX: 0, y: 100)
                hostingController.view.alpha = 0
            }, completion: { _ in
                hostingController.willMove(toParent: nil)
                hostingController.view.removeFromSuperview()
                hostingController.removeFromParent()
            })
        }
    }
}
