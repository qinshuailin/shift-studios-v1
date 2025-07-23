import SwiftUI

struct Constants {
    struct Colors {
        static let primarySwiftUI = Color(red: 0/255, green: 122/255, blue: 255/255)
        static let secondarySwiftUI = Color(red: 142/255, green: 142/255, blue: 147/255)
        static let backgroundSwiftUI = Color.white
        static let cardBackgroundSwiftUI = Color.white
        static let textSwiftUI = Color.black
        static let secondaryTextSwiftUI = Color.gray
        static let accentSwiftUI = Color(red: 0/255, green: 122/255, blue: 255/255)
    }
    struct Fonts {
        static func largeTitleSwiftUI() -> Font { Font.system(size: 34, weight: .bold, design: .default) }
        static func title3SwiftUI() -> Font { Font.system(size: 20, weight: .semibold, design: .default) }
        static func headlineSwiftUI() -> Font { Font.system(size: 17, weight: .semibold, design: .default) }
        static func subheadlineSwiftUI() -> Font { Font.system(size: 15, weight: .regular, design: .default) }
        static func footnoteSwiftUI() -> Font { Font.system(size: 13, weight: .regular, design: .default) }
    }
    struct Layout {
        static let standardSpacing: CGFloat = 16
        static let largeSpacing: CGFloat = 24
        static let cornerRadius: CGFloat = 8
        static let cardPadding: CGFloat = 16
    }
}

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
            )
    }
}
extension View {
    func swissCard() -> some View {
        self.modifier(SwissCardStyle())
    }
} 