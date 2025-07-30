import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    private func createCorrectedIcon() -> UIImage? {
        // Create high-res toggle icon in a square format with proper scaling
        let iconSize: CGFloat = 60 // Square icon size
        let toggleWidth: CGFloat = 40
        let toggleHeight: CGFloat = 24
        
        // Use 3x scale for ultra-high resolution
        UIGraphicsBeginImageContextWithOptions(CGSize(width: iconSize, height: iconSize), false, 3.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Center the toggle in the square icon
        let toggleX = (iconSize - toggleWidth) / 2
        let toggleY = (iconSize - toggleHeight) / 2
        let toggleRect = CGRect(x: toggleX, y: toggleY, width: toggleWidth, height: toggleHeight)
        
        // Draw the black toggle background (rounded rectangle)
        let cornerRadius = toggleHeight / 2
        let togglePath = UIBezierPath(roundedRect: toggleRect, cornerRadius: cornerRadius)
        UIColor.black.setFill()
        togglePath.fill()
        
        // Draw the white circle (toggle knob) on the LEFT side (OFF state)
        let knobRadius = (toggleHeight * 0.75) / 2
        let knobX = toggleX + knobRadius + (toggleHeight * 0.125)
        let knobY = toggleY + toggleHeight / 2
        let knobCenter = CGPoint(x: knobX, y: knobY)
        
        let knobPath = UIBezierPath(arcCenter: knobCenter, radius: knobRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        UIColor.white.setFill()
        knobPath.fill()
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Get the app name
        let appName = application.localizedDisplayName ?? "Blocked App"
        
        // Create the shield configuration matching homepage design
        return ShieldConfiguration(
            backgroundBlurStyle: nil,  // No blur
            backgroundColor: UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1.0), // Warmer cream tone
            icon: createCorrectedIcon() ?? UIImage(systemName: "app.fill"),
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
