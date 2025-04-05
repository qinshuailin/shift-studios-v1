import UIKit
import SwiftUI
import FamilyControls
import ManagedSettings
import CoreNFC

class MainViewController: UIViewController {
    private let appBlockingModel = AppBlockingModel.shared
    private let settingsButton = UIButton(type: .system)
    private let nfcButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    // Animation properties
    private var animationTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestScreenTimePermission()
        setupDarkMode()
        setupUI()
        NFCController.shared.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStatusLabel()
        startAnimations()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopAnimations()
    }
    
    private func setupDarkMode() {
        // Force dark mode for the entire app
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
            
            // Use UIWindowScene.windows instead of UIApplication.shared.windows (deprecated)
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        window.overrideUserInterfaceStyle = .dark
                    }
                }
            }
        }
        view.backgroundColor = .black
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
        // Status label - large, bold, centered
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "FOCUS MODE OFF"
        statusLabel.textColor = .white
        statusLabel.font = UIFont.monospacedSystemFont(ofSize: 28, weight: .bold)
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)
        
        // Description label - smaller, explains NFC functionality
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "TAP CIRCLE TO SCAN NFC"
        descriptionLabel.textColor = .gray
        descriptionLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textAlignment = .center
        view.addSubview(descriptionLabel)
        
        // NFC button - large circle in the center
        nfcButton.translatesAutoresizingMaskIntoConstraints = false
        nfcButton.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        nfcButton.layer.cornerRadius = 120
        nfcButton.clipsToBounds = true
        nfcButton.addTarget(self, action: #selector(scanNFC), for: .touchUpInside)
        
        // Add inner circle to NFC button
        let innerCircle = UIView()
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        innerCircle.layer.cornerRadius = 100
        innerCircle.tag = 100 // Tag for animation reference
        innerCircle.isUserInteractionEnabled = false // Fix: Disable user interaction to allow touches to pass through
        nfcButton.addSubview(innerCircle)
        
        // Add icon to NFC button
        let iconView = UIImageView(image: UIImage(systemName: "wave.3.right"))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false // Fix: Disable user interaction to allow touches to pass through
        nfcButton.addSubview(iconView)
        
        view.addSubview(nfcButton)
        
        // Settings button - minimal, text only
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setTitle("SELECT APPS", for: .normal)
        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        settingsButton.layer.cornerRadius = 25
        settingsButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .medium)
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        
        // Add button animation
        settingsButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        settingsButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: .touchUpOutside)
        settingsButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: .touchCancel)
        
        view.addSubview(settingsButton)
        
        NSLayoutConstraint.activate([
            // Center status label
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            
            // Description label below status
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            
            // NFC button - large circle in center
            nfcButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nfcButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            nfcButton.widthAnchor.constraint(equalToConstant: 240),
            nfcButton.heightAnchor.constraint(equalToConstant: 240),
            
            // Inner circle constraints
            innerCircle.centerXAnchor.constraint(equalTo: nfcButton.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: nfcButton.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 200),
            innerCircle.heightAnchor.constraint(equalToConstant: 200),
            
            // Icon constraints
            iconView.centerXAnchor.constraint(equalTo: nfcButton.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: nfcButton.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),
            
            // Settings button at bottom
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            settingsButton.widthAnchor.constraint(equalToConstant: 200),
            settingsButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func startAnimations() {
        // Subtle breathing animation for the inner circle
        if let innerCircle = nfcButton.viewWithTag(100) {
            let breathingAnimation = CABasicAnimation(keyPath: "transform.scale")
            breathingAnimation.fromValue = 1.0
            breathingAnimation.toValue = 1.05
            breathingAnimation.duration = 3.0
            breathingAnimation.autoreverses = true
            breathingAnimation.repeatCount = Float.infinity
            breathingAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            innerCircle.layer.add(breathingAnimation, forKey: "subtleBreathing")
        }
    }
    
    private func stopAnimations() {
        if let innerCircle = nfcButton.viewWithTag(100) {
            innerCircle.layer.removeAllAnimations()
        }
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        // Scale down animation with spring
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            sender.backgroundColor = UIColor(white: 0.2, alpha: 1.0) // Slightly lighter when pressed
        })
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        // Scale back up animation with spring
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
            sender.transform = .identity
            sender.backgroundColor = UIColor(white: 0.15, alpha: 1.0) // Back to original color
        })
    }
    
    @objc private func settingsButtonTapped() {
        // Prepare for transition animation
        let transition = CATransition()
        transition.duration = 0.4
        transition.type = .fade
        view.window?.layer.add(transition, forKey: kCATransition)
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let customPicker = AnimatedFamilyActivityPickerView(
            selection: Binding(
                get: { self.appBlockingModel.selection },
                set: {
                    self.appBlockingModel.selection = $0
                    AppBlockingManager.shared.setAppsToBlock($0)
                    
                    // Success haptic when selection is made
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            ),
            onDismiss: { self.dismiss(animated: true) }
        )
        
        let controller = UIHostingController(rootView: customPicker)
        controller.overrideUserInterfaceStyle = .dark
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    @objc private func scanNFC() {
        // Animate the NFC button when tapped
        animateNFCButtonTap()
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Begin NFC scanning - the NFCController will handle dark mode
        NFCController.shared.beginScanning()
    }
    
    private func animateNFCButtonTap() {
        // Scale animation
        UIView.animate(withDuration: 0.15, animations: {
            self.nfcButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.nfcButton.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        }, completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
                self.nfcButton.transform = .identity
                self.nfcButton.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
            })
        })
        
        // Create ripple effect
        createRippleEffect(from: nfcButton.center)
    }
    
    private func updateStatusLabel() {
        let isActive = AppBlockingManager.shared.isFocusModeActive()
        let oldText = statusLabel.text
        let newText = isActive ? "FOCUS MODE ON" : "FOCUS MODE OFF"
        
        // Only animate if text is changing
        if oldText != newText {
            // Animate text change with fade and scale
            UIView.transition(with: statusLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.statusLabel.text = newText
                
                // Change text color based on status
                self.statusLabel.textColor = isActive ? UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0) : .white
            })
            
            // Add a scale animation to the status label
            let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
            scaleAnimation.values = [1.0, 1.08, 1.0]
            scaleAnimation.keyTimes = [0, 0.5, 1]
            scaleAnimation.duration = 0.4
            statusLabel.layer.add(scaleAnimation, forKey: "scale")
            
            // Animate NFC button color change
            if let innerCircle = nfcButton.viewWithTag(100) {
                UIView.animate(withDuration: 0.5) {
                    innerCircle.backgroundColor = isActive ?
                        UIColor(red: 0.1, green: 0.3, blue: 0.1, alpha: 1.0) :
                        UIColor(white: 0.15, alpha: 1.0)
                }
            }
        }
    }
    
    private func createRippleEffect(from center: CGPoint) {
        let rippleView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        rippleView.backgroundColor = .clear
        rippleView.layer.borderColor = UIColor.white.cgColor
        rippleView.layer.borderWidth = 2
        rippleView.layer.cornerRadius = 10
        rippleView.center = center
        view.addSubview(rippleView)
        
        UIView.animate(withDuration: 0.8, animations: {
            rippleView.transform = CGAffineTransform(scaleX: 15, y: 15)
            rippleView.alpha = 0
        }, completion: { _ in
            rippleView.removeFromSuperview()
        })
    }
}

extension MainViewController: NFCControllerDelegate {
    func didScanNFCTag() {
        // Strong haptic feedback when NFC tag is scanned
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        
        // Add a ripple effect from the center
        createRippleEffect(from: nfcButton.center)
    }
    
    func didToggleFocusMode() {
        // Toggle focus mode with animation
        updateStatusLabel()
    }
}

// Custom dark mode app selection screen with animations
struct AnimatedFamilyActivityPickerView: View {
    @Binding var selection: FamilyActivitySelection
    @State private var animateBackground = false
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Content
            NavigationView {
                ZStack {
                    // Subtle animated background
                    Circle()
                        .fill(Color(UIColor(white: 0.12, alpha: 1.0)))
                        .frame(width: 300, height: 300)
                        .scaleEffect(animateBackground ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateBackground)
                        .opacity(0.5)
                        .blur(radius: 30)
                    
                    // App picker with padding to hide default title
                    FamilyActivityPicker(selection: $selection)
                        .padding(.top, -60)
                }
                .navigationBarTitle("SELECT APPS", displayMode: .inline)
                .navigationBarItems(
                    leading: Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onDismiss()
                    }) {
                        Text("CANCEL")
                            .fontWeight(.medium)
                    },
                    trailing: Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onDismiss()
                    }) {
                        Text("DONE")
                            .fontWeight(.medium)
                    }
                )
            }
            .onAppear {
                animateBackground = true
            }
        }
        .environment(\.colorScheme, .dark)
        .colorScheme(.dark)
    }
}
