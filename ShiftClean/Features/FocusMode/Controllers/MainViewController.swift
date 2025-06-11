import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings
import CoreNFC

class MainViewController: UIViewController {

    // MARK: - Properties
    private let logoLabel = UILabel()
    private let clockInContainer = UIView()
    private let clockInButton = UIButton()
    private let appSelectionContainer = UIView()
    private let appSelectionLabel = UILabel()
    private let appSelectionButton = UIButton()
    private let timeSavedLabel = UILabel()
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
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show navigation bar on other screens
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Set background color
        view.backgroundColor = .white
        
        // Setup logo label
        setupLogoLabel()
        
        // Setup clock in button
        setupClockInButton()
        
        // Setup app selection
        setupAppSelection()
        
        // Setup time saved label
        setupTimeSavedLabel()
    }
    
    private func setupLogoLabel() {
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.text = "shift."
        logoLabel.textAlignment = .left
        logoLabel.textColor = .black
        logoLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        logoLabel.alpha = 0 // Start invisible for animation
        view.addSubview(logoLabel)
        
        NSLayoutConstraint.activate([
            logoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            logoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            logoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }
    
    private func setupClockInButton() {
        // Create container view for the entire clock in section
        clockInContainer.translatesAutoresizingMaskIntoConstraints = false
        clockInContainer.backgroundColor = .white
        clockInContainer.layer.borderWidth = 1
        clockInContainer.layer.borderColor = UIColor.lightGray.cgColor
        clockInContainer.layer.cornerRadius = 8
        
        // Add shadow to container
        clockInContainer.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        clockInContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        clockInContainer.layer.shadowRadius = 4
        clockInContainer.layer.shadowOpacity = 1
        clockInContainer.clipsToBounds = false
        
        // Add tap gesture to container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(clockInContainerTapped))
        clockInContainer.addGestureRecognizer(tapGesture)
        clockInContainer.isUserInteractionEnabled = true
        
        clockInContainer.alpha = 0 // Start invisible for animation
        view.addSubview(clockInContainer)
        
        // Create clock icon
        let clockIcon = UIImageView(image: UIImage(systemName: "clock"))
        clockIcon.translatesAutoresizingMaskIntoConstraints = false
        clockIcon.tintColor = .black
        clockIcon.contentMode = .scaleAspectFit
        clockInContainer.addSubview(clockIcon)
        
        // Create text stack
        let textStack = UIStackView()
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Clock In"
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Start tracking your focus session"
        subtitleLabel.textColor = .darkGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        clockInContainer.addSubview(textStack)
        
        // Layout constraints for container
        NSLayoutConstraint.activate([
            clockInContainer.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 40),
            clockInContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            clockInContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            clockInContainer.heightAnchor.constraint(equalToConstant: 80),
            
            clockIcon.leadingAnchor.constraint(equalTo: clockInContainer.leadingAnchor, constant: 20),
            clockIcon.centerYAnchor.constraint(equalTo: clockInContainer.centerYAnchor),
            clockIcon.widthAnchor.constraint(equalToConstant: 30),
            clockIcon.heightAnchor.constraint(equalToConstant: 30),
            
            textStack.leadingAnchor.constraint(equalTo: clockIcon.trailingAnchor, constant: 15),
            textStack.trailingAnchor.constraint(equalTo: clockInContainer.trailingAnchor, constant: -20),
            textStack.centerYAnchor.constraint(equalTo: clockInContainer.centerYAnchor)
        ])
    }
    
    private func setupAppSelection() {
        // Container setup
        appSelectionContainer.translatesAutoresizingMaskIntoConstraints = false
        appSelectionContainer.backgroundColor = .white
        appSelectionContainer.layer.borderWidth = 1
        appSelectionContainer.layer.borderColor = UIColor.lightGray.cgColor
        appSelectionContainer.layer.cornerRadius = 8
        appSelectionContainer.alpha = 0 // Start invisible for animation
        view.addSubview(appSelectionContainer)
        
        // Label setup - centered
        appSelectionLabel.translatesAutoresizingMaskIntoConstraints = false
        appSelectionLabel.text = "select apps:"
        appSelectionLabel.textColor = .black
        appSelectionLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        appSelectionLabel.textAlignment = .center // Center the text
        appSelectionContainer.addSubview(appSelectionLabel)
        
        // Button setup
        appSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        appSelectionButton.setTitle("No apps selected", for: .normal)
        appSelectionButton.setTitleColor(.darkGray, for: .normal)
        appSelectionButton.contentHorizontalAlignment = .center // Center the text
        appSelectionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        appSelectionButton.backgroundColor = .white
        appSelectionButton.layer.borderWidth = 1
        appSelectionButton.layer.borderColor = UIColor.lightGray.cgColor
        appSelectionButton.layer.cornerRadius = 8
        appSelectionButton.addTarget(self, action: #selector(appSelectionButtonTapped), for: .touchUpInside)
        appSelectionContainer.addSubview(appSelectionButton)
        
        // Layout constraints - adjusted to move text down
        NSLayoutConstraint.activate([
            appSelectionContainer.topAnchor.constraint(equalTo: clockInContainer.bottomAnchor, constant: 40),
            appSelectionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            appSelectionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            appSelectionContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Center the label horizontally
            appSelectionLabel.topAnchor.constraint(equalTo: appSelectionContainer.topAnchor, constant: 15),
            appSelectionLabel.centerXAnchor.constraint(equalTo: appSelectionContainer.centerXAnchor),
            appSelectionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: appSelectionContainer.leadingAnchor, constant: 15),
            appSelectionLabel.trailingAnchor.constraint(lessThanOrEqualTo: appSelectionContainer.trailingAnchor, constant: -15),
            
            // Move the button down by increasing the top constant
            appSelectionButton.topAnchor.constraint(equalTo: appSelectionLabel.bottomAnchor, constant: 20), // Increased from 10
            appSelectionButton.leadingAnchor.constraint(equalTo: appSelectionContainer.leadingAnchor, constant: 15),
            appSelectionButton.trailingAnchor.constraint(equalTo: appSelectionContainer.trailingAnchor, constant: -15),
            appSelectionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add touch animations
        addButtonTouchAnimations(to: appSelectionButton)
    }
    
    private func setupTimeSavedLabel() {
        timeSavedLabel.translatesAutoresizingMaskIntoConstraints = false
        timeSavedLabel.text = "Time Saved Today: 0h 0m"
        timeSavedLabel.textAlignment = .center
        timeSavedLabel.textColor = .darkGray
        timeSavedLabel.font = UIFont.systemFont(ofSize: 16)
        timeSavedLabel.backgroundColor = .white
        timeSavedLabel.layer.borderWidth = 1
        timeSavedLabel.layer.borderColor = UIColor.lightGray.cgColor
        timeSavedLabel.layer.cornerRadius = 8
        timeSavedLabel.alpha = 0 // Start invisible for animation
        view.addSubview(timeSavedLabel)
        
        NSLayoutConstraint.activate([
            timeSavedLabel.topAnchor.constraint(equalTo: appSelectionContainer.bottomAnchor, constant: 40),
            timeSavedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            timeSavedLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            timeSavedLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func addButtonTouchAnimations(to button: UIButton) {
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    // MARK: - Button Touch Animations
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
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
        logoLabel.alpha = 0
        clockInContainer.alpha = 0
        appSelectionContainer.alpha = 0
        timeSavedLabel.alpha = 0
        
        // Animate each element with a delay
        UIView.animate(withDuration: 0.5, delay: 0.1, options: [], animations: {
            self.logoLabel.alpha = 1
        })
        
        UIView.animate(withDuration: 0.6, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
            self.clockInContainer.alpha = 1
            self.clockInContainer.transform = CGAffineTransform.identity
        })
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
            self.appSelectionContainer.alpha = 1
        })
        
        UIView.animate(withDuration: 0.5, delay: 0.7, options: [], animations: {
            self.timeSavedLabel.alpha = 1
        })
    }
    
    // MARK: - Action Methods
    @objc private func clockInContainerTapped() {
        // Provide haptic feedback
        impactFeedback.impactOccurred(intensity: 0.8)
        
        // Begin NFC scanning
        nfcController.beginScanning()
        
        // Removed ripple effect
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
                        
                        // Set flag that apps have been selected
                        UserDefaults.standard.set(true, forKey: "hasAppsSelected")
                        
                        // Provide success haptic feedback
                        self.notificationFeedback.notificationOccurred(.success)
                        
                        // Update UI
                        self.updateUI()
                    }
                })
        }
        .environment(\.colorScheme, .light)
        
        let controller = UIHostingController(rootView: contentView)
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    // MARK: - Helper Methods
    private func updateUI() {
        let isActive = AppBlockingService.shared.isFocusModeActive()
        
        // Find the clock icon and text labels in the container
        if let clockIcon = clockInContainer.subviews.first(where: { $0 is UIImageView }) as? UIImageView,
           let textStack = clockInContainer.subviews.first(where: { $0 is UIStackView }) as? UIStackView,
           let titleLabel = textStack.arrangedSubviews.first as? UILabel,
           let subtitleLabel = textStack.arrangedSubviews.last as? UILabel {
            
            // Update clock in button
            let clockInTitle = isActive ? "Clock Out" : "Clock In"
            let clockInSubtitle = isActive ? "End your focus session" : "Start tracking your focus session"
            
            titleLabel.text = clockInTitle
            subtitleLabel.text = clockInSubtitle
            
            // Change icon based on state
            clockIcon.image = UIImage(systemName: isActive ? "clock.fill" : "clock")
            
            // Change container appearance based on state
            if isActive {
                clockInContainer.backgroundColor = Constants.Colors.accent.withAlphaComponent(0.1)
                clockInContainer.layer.borderColor = Constants.Colors.accent.cgColor
            } else {
                clockInContainer.backgroundColor = .white
                clockInContainer.layer.borderColor = UIColor.lightGray.cgColor
            }
        }
        
        // Update app selection button
        // Fixed: Use UserDefaults to track if apps are selected instead of checking isEmpty
        let hasSelectedApps = AppBlockingService.shared.isFocusModeActive() || UserDefaults.standard.bool(forKey: "hasAppsSelected")
        appSelectionButton.setTitle(hasSelectedApps ? "Apps selected" : "No apps selected", for: .normal)
        
        // Update time saved label
        let timeSaved = StatsManager.shared.totalTimeSavedToday
        let hours = timeSaved / 60
        let minutes = timeSaved % 60
        timeSavedLabel.text = "Time Saved Today: \(hours)h \(minutes)m"
    }
}

// MARK: - NFCControllerDelegate
extension MainViewController: NFCControllerDelegate {
    func didScanNFCTag() {
        // Handle NFC tag scan
        // Update UI or provide feedback as needed
        updateUI()
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
        updateUI()
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
