import UIKit
import FamilyControls

class SettingsViewController: UIViewController {
    
    private let titleLabel = UILabel()
    private let selectAppsButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = Constants.Colors.background
        
        // Title Label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "SETTINGS"
        titleLabel.textColor = Constants.Colors.text
        titleLabel.font = Constants.Fonts.title
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Select Apps Button
        selectAppsButton.translatesAutoresizingMaskIntoConstraints = false
        selectAppsButton.setTitle("SELECT APPS TO BLOCK", for: .normal)
        selectAppsButton.setTitleColor(Constants.Colors.text, for: .normal)
        selectAppsButton.backgroundColor = Constants.Colors.background
        selectAppsButton.layer.borderWidth = 1
        selectAppsButton.layer.borderColor = Constants.Colors.text.cgColor
        selectAppsButton.titleLabel?.font = Constants.Fonts.button
        selectAppsButton.addTarget(self, action: #selector(selectAppsButtonTapped), for: .touchUpInside)
        view.addSubview(selectAppsButton)
        
        // Back Button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("BACK", for: .normal)
        backButton.setTitleColor(Constants.Colors.text, for: .normal)
        backButton.backgroundColor = Constants.Colors.background
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = Constants.Colors.text.cgColor
        backButton.titleLabel?.font = Constants.Fonts.button
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            selectAppsButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            selectAppsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectAppsButton.widthAnchor.constraint(equalToConstant: 250),
            selectAppsButton.heightAnchor.constraint(equalToConstant: 50),
            
            backButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            backButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 200),
            backButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func selectAppsButtonTapped() {
        Task {
            if let selection = await AppBlockingManager.shared.selectAppsToBlock() {
                // Present the activity selection view controller
                let activityVC = FamilyActivityPickerViewController(
                    selection: selection,
                    selectionMode: .apps
                )
                activityVC.delegate = self
                self.present(activityVC, animated: true)
            }
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - FamilyActivityPickerViewControllerDelegate
extension SettingsViewController: FamilyActivityPickerViewControllerDelegate {
    func familyActivityPickerViewControllerDidFinish(_ viewController: FamilyActivityPickerViewController) {
        viewController.dismiss(animated: true)
        
        // Get the selection and update the blocking manager
        let selection = viewController.selection
        AppBlockingManager.shared.setAppsToBlock(selection)
    }
    
    func familyActivityPickerViewControllerDidCancel(_ viewController: FamilyActivityPickerViewController) {
        viewController.dismiss(animated: true)
    }
}
