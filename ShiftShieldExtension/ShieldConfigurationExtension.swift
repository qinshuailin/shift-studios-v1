import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundColor: .black,
            icon: .init(systemName: "lock.fill"),
            title: ShieldConfiguration.Label(
                text: "Focus Mode",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Stay on track.",
                color: .gray
            )
        )
    }
}
