import UIKit

class FloatingTabBar: UIView {
    
    // MARK: - Properties
    private var tabButtons: [UIButton] = []
    private var selectedIndex: Int = 0
    private var selectionIndicator = UIView()
    private var tabSelectionCallback: ((Int) -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        // Configure container view
        backgroundColor = .white
        layer.cornerRadius = 24
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowOpacity = 0.1
        clipsToBounds = false
        
        // Add selection indicator - using black as requested
        selectionIndicator.backgroundColor = .black
        selectionIndicator.layer.cornerRadius = 18
        addSubview(selectionIndicator)
    }
    
    // MARK: - Public Methods
    func configure(with items: [(title: String, icon: String)], callback: @escaping (Int) -> Void) {
        // Clear existing buttons
        tabButtons.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()
        
        // Store callback
        tabSelectionCallback = callback
        
        // Create buttons for each tab
        for (index, item) in items.enumerated() {
            let button = createTabButton(title: item.title, icon: item.icon, index: index)
            tabButtons.append(button)
            addSubview(button)
        }
        
        // Set initial selection
        updateSelection(index: 0, animated: false)
        
        // Layout buttons
        setNeedsLayout()
    }
    
    func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < tabButtons.count else { return }
        updateSelection(index: index, animated: animated)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let buttonWidth = bounds.width / CGFloat(tabButtons.count)
        
        // Layout buttons
        for (index, button) in tabButtons.enumerated() {
            button.frame = CGRect(
                x: buttonWidth * CGFloat(index),
                y: 0,
                width: buttonWidth,
                height: bounds.height
            )
        }
        
        // Update selection indicator position
        if !tabButtons.isEmpty {
            let buttonWidth = bounds.width / CGFloat(tabButtons.count)
            let indicatorInset: CGFloat = 8
            
            selectionIndicator.frame = CGRect(
                x: buttonWidth * CGFloat(selectedIndex) + indicatorInset,
                y: indicatorInset,
                width: buttonWidth - (indicatorInset * 2),
                height: bounds.height - (indicatorInset * 2)
            )
        }
    }
    
    // MARK: - Private Methods
    private func createTabButton(title: String, icon: String, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        
        // Configure button
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        button.setTitleColor(.black, for: .normal) // Using black as requested
        button.tintColor = .black // Using black as requested
        button.tag = index
        
        // Set content layout
        button.imageEdgeInsets = UIEdgeInsets(top: -10, left: 0, bottom: 10, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 20, left: -20, bottom: 0, right: 0)
        
        // Add action
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        updateSelection(index: sender.tag, animated: true)
        tabSelectionCallback?(sender.tag)
    }
    
    private func updateSelection(index: Int, animated: Bool) {
        // Update selected index
        selectedIndex = index
        
        // Update button appearances
        for (idx, button) in tabButtons.enumerated() {
            let isSelected = idx == selectedIndex
            button.setTitleColor(isSelected ? .white : .black, for: .normal) // White text on black background
            button.tintColor = isSelected ? .white : .black // White icon on black background
        }
        
        // Animate selection indicator
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                self.layoutSubviews()
            })
        } else {
            layoutSubviews()
        }
    }
}
