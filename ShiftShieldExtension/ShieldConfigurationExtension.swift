import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Get the app name
        let appName = application.localizedDisplayName ?? "Blocked App"
        
        // Create the updated shield configuration
        return ShieldConfiguration(
            backgroundBlurStyle: nil,  // No blur
            backgroundColor: UIColor.white,
            icon: nil,
            title: .init(text: "\(appName) is currently blocked by Shift.", color: UIColor.black),
            subtitle: .init(text: "getting work done means you get to live more.\nlet's get back to work.", color: UIColor.gray),
            primaryButtonLabel: .init(text: "okay", color: UIColor.white),
            primaryButtonBackgroundColor: UIColor.black,
            secondaryButtonLabel: nil
        )
    }
}
