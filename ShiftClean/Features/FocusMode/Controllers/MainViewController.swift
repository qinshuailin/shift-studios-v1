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
    private let logoLabel = UILabel()
    private let clockInContainer = UIView()
    private let clockInButton = UIButton()
    private let appSelectionContainer = UIView()
    private let appSelectionLabel = UILabel()
    private let appSelectionButton = UIButton()
    private let timeSavedLabel = UILabel()
    private let streakContainer = UIView() // Replace streakLabel with container
    private let streakDisplayLabel = UILabel() // Current streak display
    private let goalDisplayLabel = UILabel() // Goal display (read-only)
    private let goalButton = UIButton() // Goal edit button
    private var familyActivitySelection = FamilyActivitySelection()
    private let nfcController = NFCController.shared
    private let model = MyModel.shared
    private var isPickerPresented = false
    // Add a stack view to hold all main content
    private let mainStackView = UIStackView()
    
    // Store the centerY constraint so we can update its constant dynamically
    private var mainStackViewCenterYConstraint: NSLayoutConstraint?
    
    // Haptic feedback generators
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    // Add this property for observing stats updates
    private var statsObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        nfcController.delegate = self
        // Set up live updates observer
        setupStatsObserver()
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
        // tabBarController?.tabBar.isHidden = false // <--- TEMPORARILY DISABLED
        
        // Animate content appearance
        animateContentAppearance()
        
        // Update UI based on current state
        updateUI()
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
        if let constraint = mainStackViewCenterYConstraint {
            let offset = -view.bounds.height / 6 // 1/6 up moves center to 1/3 from top
            constraint.constant = offset
        }
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
        
        // Setup streak container
        setupStreakContainer()
        
        // Setup and layout the main stack view
        setupMainStackView()
    }
    
    private func setupLogoLabel() {
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.text = "shift."
        logoLabel.textAlignment = .left
        logoLabel.textColor = .black
        logoLabel.font = UIFont.systemFont(ofSize: 44, weight: .bold)
        logoLabel.backgroundColor = .white
        logoLabel.layer.borderWidth = 0
        logoLabel.layer.borderColor = UIColor.clear.cgColor
        logoLabel.alpha = 0
        // Don't add to view here, will add to stack view later
    }
    
    private func setupClockInButton() {
        clockInContainer.translatesAutoresizingMaskIntoConstraints = false
        clockInContainer.backgroundColor = .white
        clockInContainer.layer.borderWidth = 1
        clockInContainer.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        clockInContainer.layer.cornerRadius = 8
        clockInContainer.clipsToBounds = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(clockInContainerTapped))
        clockInContainer.addGestureRecognizer(tapGesture)
        clockInContainer.isUserInteractionEnabled = true
        clockInContainer.alpha = 0
        // Don't add to view here, will add to stack view later
        let clockIcon = UIImageView(image: UIImage(systemName: "clock"))
        clockIcon.translatesAutoresizingMaskIntoConstraints = false
        clockIcon.tintColor = .black
        clockIcon.contentMode = .scaleAspectFit
        clockInContainer.addSubview(clockIcon)
        let textStack = UIStackView()
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "clock in"
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "start tracking your focus session"
        subtitleLabel.textColor = .gray
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        clockInContainer.addSubview(textStack)
        NSLayoutConstraint.activate([
            clockIcon.leadingAnchor.constraint(equalTo: clockInContainer.leadingAnchor, constant: 16),
            clockIcon.centerYAnchor.constraint(equalTo: clockInContainer.centerYAnchor),
            clockIcon.widthAnchor.constraint(equalToConstant: 28),
            clockIcon.heightAnchor.constraint(equalToConstant: 28),
            textStack.leadingAnchor.constraint(equalTo: clockIcon.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: clockInContainer.trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: clockInContainer.centerYAnchor)
        ])
        // Set a fixed height for the container
        NSLayoutConstraint.activate([
            clockInContainer.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func setupAppSelection() {
        appSelectionContainer.translatesAutoresizingMaskIntoConstraints = false
        appSelectionContainer.backgroundColor = .white
        appSelectionContainer.layer.borderWidth = 1
        appSelectionContainer.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        appSelectionContainer.layer.cornerRadius = 8
        appSelectionContainer.alpha = 0
        // Don't add to view here, will add to stack view later
        appSelectionLabel.translatesAutoresizingMaskIntoConstraints = false
        appSelectionLabel.text = "select apps:"
        appSelectionLabel.textColor = .black
        appSelectionLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        appSelectionLabel.textAlignment = .center
        appSelectionContainer.addSubview(appSelectionLabel)
        appSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        appSelectionButton.setTitle("no apps selected", for: .normal)
        appSelectionButton.setTitleColor(.black, for: .normal)
        appSelectionButton.contentHorizontalAlignment = .center
        appSelectionButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        appSelectionButton.backgroundColor = .white
        appSelectionButton.layer.borderWidth = 1
        appSelectionButton.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        appSelectionButton.layer.cornerRadius = 8
        appSelectionButton.addTarget(self, action: #selector(appSelectionButtonTapped), for: .touchUpInside)
        appSelectionContainer.addSubview(appSelectionButton)
        NSLayoutConstraint.activate([
            appSelectionLabel.topAnchor.constraint(equalTo: appSelectionContainer.topAnchor, constant: 12),
            appSelectionLabel.centerXAnchor.constraint(equalTo: appSelectionContainer.centerXAnchor),
            appSelectionButton.topAnchor.constraint(equalTo: appSelectionLabel.bottomAnchor, constant: 16),
            appSelectionButton.leadingAnchor.constraint(equalTo: appSelectionContainer.leadingAnchor, constant: 16),
            appSelectionButton.trailingAnchor.constraint(equalTo: appSelectionContainer.trailingAnchor, constant: -16),
            appSelectionButton.heightAnchor.constraint(equalToConstant: 44),
            appSelectionContainer.heightAnchor.constraint(equalToConstant: 100)
        ])
        addButtonTouchAnimations(to: appSelectionButton)
    }
    
    private func setupTimeSavedLabel() {
        timeSavedLabel.translatesAutoresizingMaskIntoConstraints = false
        timeSavedLabel.text = "time saved today: 0h 0m"
        timeSavedLabel.textAlignment = .center
        timeSavedLabel.textColor = .black
        timeSavedLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        timeSavedLabel.backgroundColor = .white
        timeSavedLabel.layer.borderWidth = 0
        timeSavedLabel.layer.borderColor = UIColor.clear.cgColor
        timeSavedLabel.layer.cornerRadius = 0
        timeSavedLabel.alpha = 0
        // Don't add to view here, will add to stack view later
        NSLayoutConstraint.activate([
            timeSavedLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupStreakContainer() {
        streakContainer.translatesAutoresizingMaskIntoConstraints = false
        streakContainer.backgroundColor = .white
        streakContainer.layer.borderWidth = 1
        streakContainer.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        streakContainer.layer.cornerRadius = 8
        streakContainer.alpha = 0      // Don't add to view here, will add to stack view later
        
        // Setup streak display label
        streakDisplayLabel.translatesAutoresizingMaskIntoConstraints = false
        streakDisplayLabel.text = "streak: 0 days"
        streakDisplayLabel.textAlignment = .center
        streakDisplayLabel.textColor = .black
        streakDisplayLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        streakContainer.addSubview(streakDisplayLabel)
        
        // Setup goal display label
        goalDisplayLabel.translatesAutoresizingMaskIntoConstraints = false
        goalDisplayLabel.text = "goal: 0h 0m"
        goalDisplayLabel.textAlignment = .center
        goalDisplayLabel.textColor = .black
        goalDisplayLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        goalDisplayLabel.backgroundColor = .white
        goalDisplayLabel.layer.borderWidth = 1
        goalDisplayLabel.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        goalDisplayLabel.layer.cornerRadius = 6
        streakContainer.addSubview(goalDisplayLabel)
        
        // Setup goal button
        goalButton.translatesAutoresizingMaskIntoConstraints = false
        goalButton.setTitle("edit", for: .normal)
        goalButton.setTitleColor(.black, for: .normal)
        goalButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        goalButton.backgroundColor = .white
        goalButton.layer.borderWidth = 1
        goalButton.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        goalButton.layer.cornerRadius = 6
        goalButton.addTarget(self, action: #selector(goalButtonTapped), for: .touchUpInside)
        streakContainer.addSubview(goalButton)
        
        NSLayoutConstraint.activate([
            streakContainer.heightAnchor.constraint(equalToConstant: 80),
            streakDisplayLabel.topAnchor.constraint(equalTo: streakContainer.topAnchor, constant: 12),
            streakDisplayLabel.centerXAnchor.constraint(equalTo: streakContainer.centerXAnchor),
            streakDisplayLabel.leadingAnchor.constraint(greaterThanOrEqualTo: streakContainer.leadingAnchor, constant: 16),
            streakDisplayLabel.trailingAnchor.constraint(lessThanOrEqualTo: streakContainer.trailingAnchor, constant: -16),
            goalDisplayLabel.topAnchor.constraint(equalTo: streakDisplayLabel.bottomAnchor, constant: 8),
            goalDisplayLabel.leadingAnchor.constraint(equalTo: streakContainer.leadingAnchor, constant: 16),
            goalDisplayLabel.heightAnchor.constraint(equalToConstant: 32),
            goalButton.topAnchor.constraint(equalTo: streakDisplayLabel.bottomAnchor, constant: 8),
            goalButton.leadingAnchor.constraint(equalTo: goalDisplayLabel.trailingAnchor, constant: 8),
            goalButton.trailingAnchor.constraint(equalTo: streakContainer.trailingAnchor, constant: -16),
            goalButton.widthAnchor.constraint(equalToConstant: 50),
            goalButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        addButtonTouchAnimations(to: goalButton)
    }
    
    private func setupMainStackView() {
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.axis = .vertical
        mainStackView.alignment = .fill
        mainStackView.distribution = .equalSpacing
        mainStackView.spacing = 18
        // Add arranged subviews
        mainStackView.addArrangedSubview(logoLabel)
        mainStackView.addArrangedSubview(clockInContainer)
        mainStackView.addArrangedSubview(appSelectionContainer)
        mainStackView.addArrangedSubview(timeSavedLabel)
        mainStackView.addArrangedSubview(streakContainer) // Add streak container to stack
        view.addSubview(mainStackView)
        // Use centerYAnchor with a constant, to be set in viewDidLayoutSubviews
        let centerY = mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        centerY.priority = UILayoutPriority.defaultHigh
        mainStackViewCenterYConstraint = centerY
        NSLayoutConstraint.activate([
            centerY,
            mainStackView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
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
        streakContainer.alpha = 0
        
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
        
        UIView.animate(withDuration: 0.5, delay: 0.9, options: [], animations: {
            self.streakContainer.alpha = 1
        })
    }
    
    // MARK: - Action Methods
    @objc private func clockInContainerTapped() {
        // Provide haptic feedback
        impactFeedback.impactOccurred(intensity: 0.8)
        
        // Print device usage data to console
        StatsManager.shared.printAppGroupUsageData()
        
        // Begin NFC scanning
        nfcController.beginScanning()
        
        // Removed ripple effect
    }
    
    @objc private func appSelectionButtonTapped() {
        let pickerSheet = ActivityPickerSheet(selection: Binding(
            get: { self.model.selectionToDiscourage },
            set: { self.model.selectionToDiscourage = $0 }
        ))
        let hostingController = UIHostingController(rootView: pickerSheet)
        present(hostingController, animated: true)
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
            let clockInTitle = isActive ? "clock out" : "clock in"
            let clockInSubtitle = isActive ? "end your focus session" : "start tracking your focus session"
            
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
        if isActive {
            appSelectionButton.setTitle("cannot change during focus", for: .normal)
            appSelectionButton.setTitleColor(.gray, for: .normal)
            appSelectionButton.backgroundColor = UIColor.systemGray6
            appSelectionButton.isEnabled = false
        } else {
            appSelectionButton.setTitle("Select apps to block", for: .normal)
            appSelectionButton.setTitleColor(.black, for: .normal)
            appSelectionButton.backgroundColor = .white
            appSelectionButton.isEnabled = true
        }
        
        // Update time saved display (this will now show live updates)
        updateTimeSavedDisplay()
        // Update streak display
        let currentStreak = StatsManager.shared.currentStreak
        streakDisplayLabel.text = "streak: \(currentStreak) days"
        // Update goal display with current goal
        let currentGoal = StatsManager.shared.dailyGoal
        let goalHours = currentGoal / 60
        let goalMinutes = currentGoal % 60
        goalDisplayLabel.text = "goal: \(goalHours)h \(goalMinutes)m"
    }
    
    // MARK: - Goal Management
    @objc private func goalButtonTapped() {
        let goalEditor = GoalEditorViewController()
        goalEditor.delegate = self
        goalEditor.modalPresentationStyle = .overFullScreen
        goalEditor.modalTransitionStyle = .crossDissolve
        present(goalEditor, animated: true)
    }
    
    // Add this new method to set up the stats observer
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
            self?.updateTimeSavedDisplay()
        }
    }
    // Add this new method to update just the time saved display
    private func updateTimeSavedDisplay() {
        let timeSaved = StatsManager.shared.totalTimeSavedToday
        let hours = timeSaved / 60
        let minutes = timeSaved % 60
        timeSavedLabel.text = "time saved today: \(hours)h \(minutes)m"
    }
    
    // Clean up observer when view controller is deallocated
    deinit {
        if let observer = statsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - GoalEditorDelegate
extension MainViewController: GoalEditorDelegate {
    func goalEditor(_ editor: GoalEditorViewController, didSetGoal goalMinutes: Int) {
        UserDefaults.standard.set(goalMinutes, forKey: "dailyGoalMinutes")
        updateUI() // Refresh the display
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
            
            // Update UI
            updateUI()
        } else {
            // Focus mode was deactivated
            // End focus session in stats manager
            StatsManager.shared.endFocusSession()
            
            // Update UI
            updateUI()
        }
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
