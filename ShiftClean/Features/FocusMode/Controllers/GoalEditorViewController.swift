import UIKit

protocol GoalEditorDelegate: AnyObject {
    func goalEditor(_ editor: GoalEditorViewController, didSetGoal goalMinutes: Int)
}

class GoalEditorViewController: UIViewController {
    
    weak var delegate: GoalEditorDelegate?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let hoursLabel = UILabel()
    private let minutesLabel = UILabel()
    private let hoursStepper = UIStepper()
    private let minutesStepper = UIStepper()
    private let hoursValueLabel = UILabel()
    private let minutesValueLabel = UILabel()
    private let saveButton = UIButton()
    private let cancelButton = UIButton()
    
    // MARK: - Properties
    private var currentHours: Int = 0
    private var currentMinutes: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentGoal()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        view.addSubview(containerView)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Set daily goal"
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        containerView.addSubview(titleLabel)
        
        // Hours section
        hoursLabel.translatesAutoresizingMaskIntoConstraints = false
        hoursLabel.text = "hours"
        hoursLabel.textAlignment = .center
        hoursLabel.textColor = .black
        hoursLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        containerView.addSubview(hoursLabel)
        
        hoursValueLabel.translatesAutoresizingMaskIntoConstraints = false
        hoursValueLabel.text = String(currentHours)
        hoursValueLabel.textAlignment = .center
        hoursValueLabel.textColor = .black
        hoursValueLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        hoursValueLabel.backgroundColor = .white
        hoursValueLabel.layer.borderWidth = 1
        hoursValueLabel.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        hoursValueLabel.layer.cornerRadius = 8
        containerView.addSubview(hoursValueLabel)
        
        hoursStepper.translatesAutoresizingMaskIntoConstraints = false
        hoursStepper.minimumValue = 0
        hoursStepper.maximumValue = 24
        hoursStepper.value = Double(currentHours)
        hoursStepper.addTarget(self, action: #selector(hoursChanged), for: .valueChanged)
        containerView.addSubview(hoursStepper)
        
        // Minutes section
        minutesLabel.translatesAutoresizingMaskIntoConstraints = false
        minutesLabel.text = "minutes"
        minutesLabel.textAlignment = .center
        minutesLabel.textColor = .black
        minutesLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        containerView.addSubview(minutesLabel)
        
        minutesValueLabel.translatesAutoresizingMaskIntoConstraints = false
        minutesValueLabel.text = String(currentMinutes)
        minutesValueLabel.textAlignment = .center
        minutesValueLabel.textColor = .black
        minutesValueLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        minutesValueLabel.backgroundColor = .white
        minutesValueLabel.layer.borderWidth = 1
        minutesValueLabel.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        minutesValueLabel.layer.cornerRadius = 8
        containerView.addSubview(minutesValueLabel)
        
        minutesStepper.translatesAutoresizingMaskIntoConstraints = false
        minutesStepper.minimumValue = 0
        minutesStepper.maximumValue = 59
        minutesStepper.value = Double(currentMinutes)
        minutesStepper.addTarget(self, action: #selector(minutesChanged), for: .valueChanged)
        containerView.addSubview(minutesStepper)
        
        // Buttons
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("save", for: .normal)
        saveButton.setTitleColor(.black, for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveButton.backgroundColor = .white
        saveButton.layer.borderWidth = 1
        saveButton.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        containerView.addSubview(saveButton)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("cancel", for: .normal)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = .white
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        containerView.addSubview(cancelButton)
        
        // Layout
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 450),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Hours section
            hoursLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            hoursLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            hoursValueLabel.topAnchor.constraint(equalTo: hoursLabel.bottomAnchor, constant: 12),
            hoursValueLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            hoursValueLabel.widthAnchor.constraint(equalToConstant: 80),
            hoursValueLabel.heightAnchor.constraint(equalToConstant: 60),
            
            hoursStepper.topAnchor.constraint(equalTo: hoursValueLabel.bottomAnchor, constant: 12),
            hoursStepper.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Minutes section
            minutesLabel.topAnchor.constraint(equalTo: hoursStepper.bottomAnchor, constant: 24),
            minutesLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            minutesValueLabel.topAnchor.constraint(equalTo: minutesLabel.bottomAnchor, constant: 12),
            minutesValueLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            minutesValueLabel.widthAnchor.constraint(equalToConstant: 80),
            minutesValueLabel.heightAnchor.constraint(equalToConstant: 60),
            
            minutesStepper.topAnchor.constraint(equalTo: minutesValueLabel.bottomAnchor, constant: 12),
            minutesStepper.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Buttons - moved further down with more spacing
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            saveButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            cancelButton.leadingAnchor.constraint(equalTo: saveButton.trailingAnchor, constant: 16),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.widthAnchor.constraint(equalTo: saveButton.widthAnchor)
        ])
        
        // Add tap gesture to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func loadCurrentGoal() {
        let currentGoal = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
        currentHours = currentGoal / 60
        currentMinutes = currentGoal % 60
        hoursStepper.value = Double(currentHours)
        minutesStepper.value = Double(currentMinutes)
        updateLabels()
    }
    
    private func updateLabels() {
        hoursValueLabel.text = String(currentHours)
        minutesValueLabel.text = String(currentMinutes)
    }
    
    // MARK: - Actions
    @objc private func hoursChanged() {
        currentHours = Int(hoursStepper.value)
        updateLabels()
        Constants.Haptics.stepperChange()
    }
    
    @objc private func minutesChanged() {
        currentMinutes = Int(minutesStepper.value)
        updateLabels()
        Constants.Haptics.stepperChange()
    }
    
    @objc private func saveTapped() {
        let totalMinutes = (currentHours * 60) + currentMinutes
        delegate?.goalEditor(self, didSetGoal: totalMinutes)
        Constants.Haptics.goalSet()
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        Constants.Haptics.buttonPress()
        dismiss(animated: true)
    }
    
    @objc private func backgroundTapped() {
        dismiss(animated: true)
    }
} 