import UIKit
import SwiftUI

struct Constants {
    
    // MARK: - Colors
    struct Colors {
        static let background = UIColor(red: 0.96, green: 0.94, blue: 0.91, alpha: 1.0)
        static let text = UIColor.black
        static let primary = UIColor.black
        static let cardBackground = UIColor.white
        static let secondaryText = UIColor.darkGray
        
        // SwiftUI Colors
        static let backgroundSwiftUI = Color(red: 0.96, green: 0.94, blue: 0.91)
        static let textSwiftUI = Color.black
        static let primarySwiftUI = Color.black
        static let cardBackgroundSwiftUI = Color.white
        static let secondaryTextSwiftUI = Color.gray
    }
    
    // MARK: - Fonts
    struct Fonts {
        static let title = UIFont.systemFont(ofSize: 32, weight: .light)
        static let headline = UIFont.systemFont(ofSize: 24, weight: .medium)
        static let subheadline = UIFont.systemFont(ofSize: 18, weight: .regular)
        static let body = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let caption = UIFont.systemFont(ofSize: 14, weight: .light)
        static let button = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        // SwiftUI Fonts
        static func titleSwiftUI() -> Font { .system(size: 32, weight: .light) }
        static func headlineSwiftUI() -> Font { .system(size: 24, weight: .medium) }
        static func subheadlineSwiftUI() -> Font { .system(size: 18, weight: .regular) }
        static func bodySwiftUI() -> Font { .system(size: 16, weight: .regular) }
        static func captionSwiftUI() -> Font { .system(size: 14, weight: .light) }
        static func buttonSwiftUI() -> Font { .system(size: 18, weight: .medium) }
        static func footnoteSwiftUI() -> Font { .system(size: 12, weight: .regular) }
        static func title3SwiftUI() -> Font { .system(size: 20, weight: .semibold) }
        static func largeTitleSwiftUI() -> Font { .system(size: 34, weight: .bold) }
        static func title1SwiftUI() -> Font { .system(size: 28, weight: .bold) }
        static func title2SwiftUI() -> Font { .system(size: 22, weight: .bold) }
        static func calloutSwiftUI() -> Font { .system(size: 16, weight: .regular) }
        static func caption1SwiftUI() -> Font { .system(size: 12, weight: .regular) }
        static func caption2SwiftUI() -> Font { .system(size: 11, weight: .regular) }
    }
    
    // MARK: - Layout
    struct Layout {
        static let standardSpacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 24
        static let cornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
        static let cardPadding: CGFloat = 16
    }
    
    // MARK: - Notifications
    struct Notifications {
        static let focusModeToggled = "FocusModeToggled"
        static let focusModeEnabled = "FocusModeEnabled"
        static let focusModeDisabled = "FocusModeDisabled"
        static let goalUpdated = "GoalUpdated"
        static let appsSelected = "AppsSelected"
        static let statsUpdated = "StatsUpdated"
    }
    
    // MARK: - Haptic Feedback
    struct Haptics {
        
        // MARK: - Enhanced Haptic Management
        private static var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
        private static var notificationGenerator = UINotificationFeedbackGenerator()
        private static var selectionGenerator = UISelectionFeedbackGenerator()
        
        /// Initialize and pre-warm all haptic generators for instant response
        static func initialize() {
            // Pre-create and prepare all generators
            impactGenerators[.light] = UIImpactFeedbackGenerator(style: .light)
            impactGenerators[.medium] = UIImpactFeedbackGenerator(style: .medium)
            impactGenerators[.heavy] = UIImpactFeedbackGenerator(style: .heavy)
            
            // Pre-warm all generators
            impactGenerators.values.forEach { $0.prepare() }
            notificationGenerator.prepare()
            selectionGenerator.prepare()
        }
        
        /// Keep generators warm for responsive feedback
        private static func keepWarm() {
            impactGenerators.values.forEach { $0.prepare() }
            notificationGenerator.prepare()
            selectionGenerator.prepare()
        }
        
        // MARK: - Basic Haptic Patterns
        
        /// Ultra-light impact for subtle micro-interactions - INSTANT
        static func ultraLight() {
            // INSTANT response - no keepWarm delay, direct execution
            impactGenerators[.light]?.impactOccurred(intensity: 0.3)
        }
        
        /// Light impact for subtle interactions
        static func light() {
            keepWarm()
            impactGenerators[.light]?.impactOccurred(intensity: 0.7)
        }
        
        /// Medium impact for standard interactions
        static func medium() {
            keepWarm()
            impactGenerators[.medium]?.impactOccurred(intensity: 0.8)
        }
        
        /// Heavy impact for significant interactions
        static func heavy() {
            keepWarm()
            impactGenerators[.heavy]?.impactOccurred(intensity: 1.0)
        }
        
        /// Success notification feedback
        static func success() {
            keepWarm()
            notificationGenerator.notificationOccurred(.success)
        }
        
        /// Warning notification feedback
        static func warning() {
            keepWarm()
            notificationGenerator.notificationOccurred(.warning)
        }
        
        /// Error notification feedback - CUSTOM TWO PULSES
        static func error() {
            // Custom error pattern: two small pulses
            light()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                light()
            }
        }
        
        /// Selection feedback for UI elements
        static func selection() {
            keepWarm()
            selectionGenerator.selectionChanged()
        }
        
        // MARK: - Enhanced Interaction Patterns
        
        /// Button press with immediate response - SINGLE PULSE
        static func buttonPress() {
            ultraLight()
        }
        
        /// Button press for primary actions - SINGLE PULSE
        static func primaryButtonPress() {
            light()
        }
        
        /// Tab or segment selection - SINGLE PULSE
        static func tabSelection() {
            selection()
        }
        
        /// Stepper increment/decrement - SINGLE PULSE
        static func stepperChange() {
            selection()
        }
        
        /// Toggle switch - TWO CLEAN PULSES
        static func toggleSwitch() {
            medium()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                ultraLight()
            }
        }
        
        // MARK: - App-Specific Enhanced Patterns
        
        /// Focus mode activation - SINGLE crisp success
        static func focusActivated() {
            success()
        }
        
        /// Focus mode deactivation - SINGLE medium pulse
        static func focusDeactivated() {
            medium()
        }
        
        /// Goal setting - SINGLE success pulse
        static func goalSet() {
            success()
        }
        
        /// App selection - SINGLE light pulse
        static func appSelected() {
            light()
        }
        
        /// Photo selection - SINGLE success pulse
        static func photoSelected() {
            success()
        }
        
        // MARK: - NFC Enhanced Patterns
        
        /// NFC scan initiated - SINGLE medium pulse
        static func nfcScanStart() {
            medium()
        }
        
        /// NFC scan success - SINGLE strong success
        static func nfcScanSuccess() {
            success()
        }
        
        /// NFC scan error - SINGLE error pulse
        static func nfcScanError() {
            error()
        }
        
        /// NFC scan cancellation - SINGLE ultra-light pulse
        static func nfcScanCanceled() {
            ultraLight()
        }
        
        // MARK: - Live Activity Patterns
        
        /// Live Activity start - SINGLE light pulse
        static func liveActivityStart() {
            light()
        }
        
        /// Live Activity milestone - SINGLE ultra-light pulse
        static func liveActivityMilestone() {
            ultraLight()
        }
        
        /// Live Activity completion - SINGLE success pulse
        static func liveActivityComplete() {
            success()
        }
        
        // MARK: - Progressive Patterns
        
        /// Progressive pattern for loading states - SINGLE ultra-light
        static func progressStart() {
            ultraLight()
        }
        
        /// Progress step - SINGLE ultra-light
        static func progressStep() {
            ultraLight()
        }
        
        /// Progress complete - SINGLE light pulse
        static func progressComplete() {
            light()
        }
        
        // MARK: - Error Prevention
        
        /// Gentle warning - SINGLE warning pulse
        static func gentleWarning() {
            warning()
        }
        
        /// Destructive confirmation - SINGLE heavy pulse
        static func destructiveConfirmation() {
            heavy()
        }
    }
    
    // MARK: - Haptic Types
    enum HapticType {
        case ultraLight
        case light
        case medium
        case heavy
        case success
        case warning
        case error
        case selection
        case buttonPress
        case primaryButtonPress
        case tabSelection
        case stepperChange
        case toggleSwitch
        case focusActivated
        case focusDeactivated
        case goalSet
        case appSelected
        case nfcScanStart
        case nfcScanSuccess
        case nfcScanError
        case nfcScanCanceled
        case liveActivityStart
        case liveActivityMilestone
        case liveActivityComplete
        case progressStart
        case progressStep
        case progressComplete
        case gentleWarning
        case destructiveConfirmation
    }
    
    // Helper function to convert minutes to hours and minutes format
    static func formatMinutesToHoursAndMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours) hr\(hours == 1 ? "" : "s") \(remainingMinutes) min\(remainingMinutes == 1 ? "" : "s")"
        } else {
            return "\(minutes) min\(minutes == 1 ? "" : "s")"
        }
    }
}

// SwiftUI helper for consistent styling
struct SwissCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Constants.Layout.cardPadding)
            .background(Constants.Colors.cardBackgroundSwiftUI)
            .cornerRadius(Constants.Layout.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            ) // Adding thin border for Swiss design aesthetic
    }
}

extension View {
    func swissCard() -> some View {
        self.modifier(SwissCardStyle())
    }
}
