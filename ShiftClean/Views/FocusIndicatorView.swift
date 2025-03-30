import UIKit

class FocusIndicatorView: UIView {
    
    private let activeColor: UIColor = .white
    private let inactiveColor: UIColor = .gray
    
    var isActive: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = inactiveColor
        layer.cornerRadius = 0 // Sharp corners for brutalist style
    }
    
    private func updateAppearance() {
        UIView.animate(withDuration: 0.3) {
            self.backgroundColor = self.isActive ? self.activeColor : self.inactiveColor
        }
    }
}
