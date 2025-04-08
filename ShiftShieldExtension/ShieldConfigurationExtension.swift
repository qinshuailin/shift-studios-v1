import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Get the app name
        let appName = application.localizedDisplayName ?? "Blocked App"
        
        // Try with a darker color that's not pure black
        let almostBlack = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
        
        // Create a brutalist shield configuration
        return ShieldConfiguration(
            backgroundBlurStyle: .dark,  // Try with dark blur instead of nil
            backgroundColor: almostBlack,
            icon: nil,
            title: .init(text: "\(appName.uppercased()) IS BLOCKED", color: UIColor.white),
            subtitle: .init(text: "FOCUS MODE ACTIVE", color: UIColor.gray),
            primaryButtonLabel: .init(text: "CLOSE", color: UIColor.black),
            primaryButtonBackgroundColor: UIColor.white,
            secondaryButtonLabel: nil
        )
    }
}
