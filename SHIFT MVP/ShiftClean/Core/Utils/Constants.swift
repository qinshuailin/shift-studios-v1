import UIKit
import SwiftUI

struct Constants {
    struct Colors {
        // Swiss design principles - clean, minimal color palette with proper light theme
        static let primary = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0)
        static let secondary = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1.0)
        
        // Explicitly set light theme colors (black on white)
        static let background = UIColor.white
        static let cardBackground = UIColor.white
        static let text = UIColor.black
        static let secondaryText = UIColor.darkGray
        
        // Add missing color properties that were referenced in the original code
        static let accent = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0)
        
        // SwiftUI Colors - explicitly set for light theme
        static let primarySwiftUI = Color(primary)
        static let secondarySwiftUI = Color(secondary)
        static let backgroundSwiftUI = Color.white
        static let cardBackgroundSwiftUI = Color.white
        static let textSwiftUI = Color.black
        static let secondaryTextSwiftUI = Color.gray
        static let accentSwiftUI = Color(accent)
    }
    
    struct Fonts {
        // Swiss design principles - clean, sans-serif typography
        // Using Helvetica-inspired fonts which are central to Swiss design
        static let largeTitle = UIFont.systemFont(ofSize: 34, weight: .bold)
        static let title1 = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let title2 = UIFont.systemFont(ofSize: 22, weight: .bold)
        static let title3 = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 17, weight: .regular)
        static let callout = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let subheadline = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let footnote = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let caption1 = UIFont.systemFont(ofSize: 12, weight: .regular)
        static let caption2 = UIFont.systemFont(ofSize: 11, weight: .regular)
        
        // Add missing font properties that were referenced in the original code
        static let title = UIFont.systemFont(ofSize: 24, weight: .bold)
        static let button = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        // SwiftUI Fonts
        static func largeTitleSwiftUI() -> Font { Font.system(size: 34, weight: .bold, design: .default) }
        static func title1SwiftUI() -> Font { Font.system(size: 28, weight: .bold, design: .default) }
        static func title2SwiftUI() -> Font { Font.system(size: 22, weight: .bold, design: .default) }
        static func title3SwiftUI() -> Font { Font.system(size: 20, weight: .semibold, design: .default) }
        static func headlineSwiftUI() -> Font { Font.system(size: 17, weight: .semibold, design: .default) }
        static func bodySwiftUI() -> Font { Font.system(size: 17, weight: .regular, design: .default) }
        static func calloutSwiftUI() -> Font { Font.system(size: 16, weight: .regular, design: .default) }
        static func subheadlineSwiftUI() -> Font { Font.system(size: 15, weight: .regular, design: .default) }
        static func footnoteSwiftUI() -> Font { Font.system(size: 13, weight: .regular, design: .default) }
        static func caption1SwiftUI() -> Font { Font.system(size: 12, weight: .regular, design: .default) }
        static func caption2SwiftUI() -> Font { Font.system(size: 11, weight: .regular, design: .default) }
        static func titleSwiftUI() -> Font { Font.system(size: 24, weight: .bold, design: .default) }
        static func buttonSwiftUI() -> Font { Font.system(size: 16, weight: .semibold, design: .default) }
    }
    
    struct Layout {
        // Swiss design principles - consistent spacing and grid
        static let standardSpacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 24
        static let cornerRadius: CGFloat = 8  // Reduced for more Swiss-like minimalism
        static let smallCornerRadius: CGFloat = 4
        static let cardPadding: CGFloat = 16
    }
    
    // Add Notifications struct for notification names
    struct Notifications {
        // Notification names for focus mode
        static let focusModeToggled = "focusModeToggled"
        static let focusModeEnabled = "focusModeEnabled"
        static let focusModeDisabled = "focusModeDisabled"
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
