import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Get the app name
        let appName = application.localizedDisplayName ?? "Blocked App"
        
        // Create the shield configuration matching homepage design
        return ShieldConfiguration(
            backgroundBlurStyle: nil,  // No blur
            backgroundColor: UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1.0), // Warmer cream tone
            icon: nil,
            title: .init(
                text: "\(appName) is currently blocked by Shift.", 
                color: UIColor.black
            ),
            subtitle: .init(
                text: "getting work done means you get to live more.\nlet's get back to work.", 
                color: UIColor.black.withAlphaComponent(0.6)
            ),
            primaryButtonLabel: .init(
                text: "okay", 
                color: UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1.0) // Light text on dark button
            ),
            primaryButtonBackgroundColor: UIColor.black, // Black button like homepage style
            secondaryButtonLabel: nil
        )
    }
}
