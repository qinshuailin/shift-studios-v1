import UIKit

struct Constants {
    struct Colors {
        static let background = UIColor.black
        static let text = UIColor.white
        static let accent = UIColor.white
        static let inactive = UIColor.gray
    }
    
    struct Fonts {
        static let title = UIFont.systemFont(ofSize: 24, weight: .bold)
        static let body = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let button = UIFont.systemFont(ofSize: 16, weight: .bold)
    }
    
    struct NFC {
        static let companyTagPrefix = "ShiftStudios-"
        static let scanMessage = "Hold your iPhone near a Shift Studios tag"
    }
}
