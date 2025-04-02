import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // DEBUG: Confirm this is running
        print("🚫 Shield triggered for: \(application.localizedDisplayName ?? "Unknown App")")

        let appName = application.localizedDisplayName ?? "Blocked App"

        return ShieldConfiguration(
            backgroundColor: .black,
            icon: nil, // Remove default hourglass icon
            title: ShieldConfiguration.Label(
                text: appName.uppercased(),
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Focus mode active.",
                color: .gray
            )
        )
    }
}
