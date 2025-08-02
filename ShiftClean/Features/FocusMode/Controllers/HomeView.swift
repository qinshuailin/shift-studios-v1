import SwiftUI
import PhotosUI
import Photos
import FamilyControls
import MessageUI

// MARK: - Global User Manager
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "globalUserName")
            NotificationCenter.default.post(name: NSNotification.Name("UserNameChanged"), object: userName)
        }
    }
    
    private init() {
        self.userName = UserDefaults.standard.string(forKey: "globalUserName") ?? "sarah"
    }
    
    func updateName(_ newName: String) {
        userName = newName
    }
}

class NFCDelegateHandler: NSObject, ObservableObject, NFCControllerDelegate {
    @Published var didScanTag: Bool = false
    func didScanNFCTag() {
        if AppBlockingService.shared.isFocusModeActive() {
            AppBlockingService.shared.deactivateFocusMode()
        } else {
            AppBlockingService.shared.activateFocusMode()
        }
        didScanTag = true
    }
    func didToggleFocusMode() {
        let isActive = AppBlockingService.shared.isFocusModeActive()
        if isActive {
            StatsManager.shared.startFocusSession()
        } else {
            StatsManager.shared.endFocusSession()
        }
    }
    func didDetectTagWithID(tagID: String) {
        // Implement if needed
    }
}

struct GrayOutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .background(
                configuration.isPressed ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.96, green: 0.94, blue: 0.91)
            )
    }
}

struct HomeView: View {
    @ObservedObject var statsManager = StatsManager.shared
    @State private var showGoalEditor = false
    @State private var showAppPicker = false
    @ObservedObject private var userManager = UserManager.shared
    @ObservedObject var myModel = MyModel.shared
    @State private var familyActivitySelection = FamilyActivitySelection()
    @StateObject private var nfcDelegate = NFCDelegateHandler()
    @State private var clockInPressed = false
    @State private var editAppsPressed = false
    @State private var showSettingsMenu = false
    
    var isFocusModeActive: Bool {
        AppBlockingService.shared.isFocusModeActive()
    }
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {    
                    // Section 1
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                                                    Text("hi \(userManager.userName)")
                            .font(.system(size: 40, weight: .light, design: .default))
                            Spacer()
                            Button(action: {
                                Constants.Haptics.primaryButtonPress()
                                showSettingsMenu = true
                            }) {
                                ProfileImageView(size: 35)
                                    .offset(y: 1)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        Text("how will you choose to spend your day?")
                            .font(.system(size: 32, weight: .light, design: .default))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    Divider()
                    // Section 2
                    VStack(alignment: .leading, spacing: 0) {
                        Text(formattedTime(statsManager.totalTimeSavedToday))
                            .font(.system(size: 96, weight: .light, design: .default))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)
                            .padding(.top, 12)
                        Text("SAVED TODAY")
                            .font(.system(size: 18, weight: .light, design: .default))
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    Divider()
                    // Clock In/Out button
                    Button(action: {
                        Constants.Haptics.primaryButtonPress()
                        clockInPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            NFCController.shared.delegate = nfcDelegate
                            NFCController.shared.beginScanning()
                            withAnimation(.easeInOut(duration: 0.15)) {
                                clockInPressed = false
                            }
                        }
                    }) {
                        HStack {
                            Text(statsManager.isFocusModeActive ? "Clock Out" : "Clock In")
                                .font(.system(size: 40, weight: .light, design: .default))
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .contentShape(Rectangle())
                        .background(clockInPressed ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.96, green: 0.94, blue: 0.91))
                        .animation(.easeInOut(duration: 0.15), value: clockInPressed)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider()
                    // Edit Apps button
                    Button(action: {
                        // Disable action when focus mode is active
                        guard !statsManager.isFocusModeActive else { return }
                        
                        Constants.Haptics.primaryButtonPress() // Same as Clock In/Out
                        editAppsPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            showAppPicker = true
                            withAnimation(.easeInOut(duration: 0.15)) {
                                editAppsPressed = false
                            }
                        }
                    }) {
                        HStack {
                            Text("Edit Apps")
                                .font(.system(size: 40, weight: .light, design: .default))
                                .foregroundColor(statsManager.isFocusModeActive ? .gray : .black)
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .contentShape(Rectangle())
                        .background(
                            statsManager.isFocusModeActive ? 
                            Color(red: 0.92, green: 0.92, blue: 0.92) : // Grayed out background when disabled
                            (editAppsPressed ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.96, green: 0.94, blue: 0.91))
                        )
                        .animation(.easeInOut(duration: 0.15), value: editAppsPressed)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(statsManager.isFocusModeActive)
                    Divider()
                    // Section 5
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Goal")
                            .font(.system(size: 40, weight: .light, design: .default))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)
                            .padding(.vertical, 16)
                        HStack(alignment: .center) {
                            Text(formattedTime(statsManager.dailyGoal))
                                .font(.system(size: 18, weight: .light, design: .default))
                            Spacer()
                                                Button(action: { 
                        Constants.Haptics.primaryButtonPress() // Same as Clock In/Out and Edit Apps
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showGoalEditor = true
                        }
                    }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .light, design: .default))
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 2)
                        ZStack(alignment: .leading) {
                            GeometryReader { geometry in
                                let totalWidth = geometry.size.width
                                let progress = statsManager.dailyGoal > 0 ? CGFloat(statsManager.totalTimeSavedToday) / CGFloat(statsManager.dailyGoal) : 0
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(height: 16)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black)
                                    .frame(width: totalWidth * min(progress, 1.0), height: 16)
                            }
                            .frame(height: 16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    

                }
                .padding(.top, 10)
                .padding(.bottom, 10) // This controls the bottom space of the page
                .foregroundColor(.black)
            }
            .background(Color(red: 0.96, green: 0.94, blue: 0.91))
            // Custom fade-in modal overlay for Goal Editor
            ZStack {
                if showGoalEditor {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture { 
                                withAnimation(.easeInOut(duration: 0.3)) { 
                                    showGoalEditor = false 
                                } 
                            }
                        GoalEditorSheet(isPresented: $showGoalEditor)
                    }
                    .opacity(showGoalEditor ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showGoalEditor)
                }
            }
        }
        .fullScreenCover(isPresented: $showAppPicker) {
            ActivityPickerSheet(selection: $myModel.selectionToDiscourage)
                .preferredColorScheme(.light)
        }
        .fullScreenCover(isPresented: $showSettingsMenu) {
            SettingsMenuView(isPresented: $showSettingsMenu)
                .preferredColorScheme(.light)
        }
        .onAppear {
            NFCController.shared.delegate = nfcDelegate
        }
        // Remove .sheet for showGoalEditor
    }

    // Helper to format minutes as "Xh Ym"
    func formattedTime(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return "\(h)h \(m)m"
        } else {
            return "\(m)m"
        }
    }
}

// SwiftUI Goal Editor Sheet
struct GoalEditorSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var statsManager = StatsManager.shared
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var cancelPressed = false
    @State private var savePressed = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { 
                    withAnimation(.easeInOut(duration: 0.3)) { 
                        isPresented = false 
                    } 
                }
            VStack(spacing: 32) {
                Text("Set daily goal")
                    .font(.system(size: 32, weight: .light, design: .default))
                    .foregroundColor(.black)
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("hours")
                            .font(.system(size: 18, weight: .light, design: .default))
                            .foregroundColor(.black)
                        Text("\(hours)")
                            .font(.system(size: 32, weight: .light, design: .default))
                            .foregroundColor(.black)
                        Stepper("", value: $hours, in: 0...23)
                            .labelsHidden()
                        Button(action: {
                            Constants.Haptics.primaryButtonPress()
                            cancelPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false 
                                    cancelPressed = false
                                }
                            }
                        }) {
                            Text("cancel")
                                .font(.system(size: 20, weight: .light, design: .default))
                                .foregroundColor(.black)
                                .opacity(cancelPressed ? 0.5 : 1.0)
                        }
                        .padding(.top, 8)
                        .animation(.easeInOut(duration: 0.15), value: cancelPressed)
                        .buttonStyle(PlainButtonStyle())
                    }
                    VStack(spacing: 8) {
                        Text("minutes")
                            .font(.system(size: 18, weight: .light, design: .default))
                            .foregroundColor(.black)
                        Text("\(minutes)")
                            .font(.system(size: 32, weight: .light, design: .default))
                            .foregroundColor(.black)
                        Stepper("", value: $minutes, in: 0...59)
                            .labelsHidden()
                        Button(action: {
                            Constants.Haptics.primaryButtonPress()
                            savePressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                let total = hours * 60 + minutes
                                UserDefaults.standard.set(total, forKey: "dailyGoalMinutes")
                                statsManager.dailyGoal = total
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                    savePressed = false
                                }
                            }
                        }) {
                            Text("save")
                                .font(.system(size: 20, weight: .light, design: .default))
                                .foregroundColor(.black)
                                .opacity(savePressed ? 0.5 : 1.0)
                        }
                        .padding(.top, 8)
                        .animation(.easeInOut(duration: 0.15), value: savePressed)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 8)
            }
            .padding(36)
            .background(Color(red: 0.96, green: 0.94, blue: 0.91))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.10), radius: 24, x: 0, y: 8)
            .frame(minWidth: 320, maxWidth: 360)
        }
        .onAppear {
            let total = statsManager.dailyGoal
            hours = total / 60
            minutes = total % 60
        }
    }
}

struct FadeTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.gray : Color.black)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Settings Menu View
struct SettingsMenuView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var userManager = UserManager.shared
    @State private var profilePressed = false
    @State private var contactPressed = false
    @State private var suggestPressed = false
    @State private var privacyPressed = false
    @State private var termsPressed = false
    @State private var showEmailConfirmation = false
    @State private var pendingEmailSubject = ""
    @State private var showProfileEditor = false
    @State private var showExternalLinkConfirmation = false
    @State private var pendingExternalURL = ""
    @State private var pendingLinkTitle = ""

    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Profile Section (bigger)
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("settings")
                                .font(.system(size: 40, weight: .light, design: .default))
                            Spacer()
                            Button(action: {
                                Constants.Haptics.primaryButtonPress()
                                isPresented = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 22, weight: .light, design: .default))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    
                    Divider()
                    
                    // Profile Section
                    Button(action: {
                        Constants.Haptics.primaryButtonPress()
                        profilePressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            showNativeProfileEditor()
                            withAnimation(.easeInOut(duration: 0.15)) {
                                profilePressed = false
                            }
                        }
                    }) {
                        HStack(alignment: .center, spacing: 20) {
                            ProfileImageView(size: 80)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(userManager.userName)
                                    .font(.system(size: 32, weight: .light, design: .default))
                                    .foregroundColor(.black)
                                Text("tap to edit profile")
                                    .font(.system(size: 18, weight: .light, design: .default))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .background(profilePressed ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.96, green: 0.94, blue: 0.91))
                        .animation(.easeInOut(duration: 0.15), value: profilePressed)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    // Contact Us button
                    Button(action: {
                        Constants.Haptics.primaryButtonPress()
                        contactPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            pendingEmailSubject = "Contact - Shift App Support"
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEmailConfirmation = true
                            }
                            withAnimation(.easeInOut(duration: 0.15)) {
                                contactPressed = false
                            }
                        }
                    }) {
                        HStack {
                            Text("Contact Us")
                                .font(.system(size: 32, weight: .light, design: .default))
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .contentShape(Rectangle())
                        .background(contactPressed ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.96, green: 0.94, blue: 0.91))
                        .animation(.easeInOut(duration: 0.15), value: contactPressed)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    // Suggest Features button
                    Button(action: {
                        Constants.Haptics.primaryButtonPress()
                        suggestPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            pendingEmailSubject = "Feature Suggestion - Shift App"
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEmailConfirmation = true
                            }
                            withAnimation(.easeInOut(duration: 0.15)) {
                                suggestPressed = false
                            }
                        }
                    }) {
                        HStack {
                            Text("Suggest Features")
                                .font(.system(size: 32, weight: .light, design: .default))
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .contentShape(Rectangle())
                        .background(suggestPressed ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.96, green: 0.94, blue: 0.91))
                        .animation(.easeInOut(duration: 0.15), value: suggestPressed)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    // Privacy Policy button
                    Button(action: {
                        Constants.Haptics.primaryButtonPress()
                        privacyPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            pendingExternalURL = "https://shiftstudios.space/policies/privacy-policy"
                            pendingLinkTitle = "Privacy Policy"
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showExternalLinkConfirmation = true
                                privacyPressed = false
                            }
                        }
                    }) {
                        HStack {
                            Text("Privacy Policy")
                                .font(.system(size: 32, weight: .light, design: .default))
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .contentShape(Rectangle())
                        .background(privacyPressed ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.96, green: 0.94, blue: 0.91))
                        .animation(.easeInOut(duration: 0.15), value: privacyPressed)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    // Terms of Service button
                    Button(action: {
                        Constants.Haptics.primaryButtonPress()
                        termsPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            pendingExternalURL = "https://shiftstudios.space/policies/terms-of-service"
                            pendingLinkTitle = "TOS"
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showExternalLinkConfirmation = true
                                termsPressed = false
                            }
                        }
                    }) {
                        HStack {
                            Text("Terms of Service")
                                .font(.system(size: 32, weight: .light, design: .default))
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .contentShape(Rectangle())
                        .background(termsPressed ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.96, green: 0.94, blue: 0.91))
                        .animation(.easeInOut(duration: 0.15), value: termsPressed)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    // Version info at bottom
                    VStack {
                        Spacer()
                        Text("Version \(appVersion)")
                            .font(.system(size: 14, weight: .light, design: .default))
                            .foregroundColor(.black.opacity(0.6))
                            .padding(.bottom, 40)
                    }
                    .frame(minHeight: 100)
                }
                .padding(.top, 10)
                .foregroundColor(.black)
            }
            .background(Color(red: 0.96, green: 0.94, blue: 0.91))
            
            // Email confirmation overlay
            ZStack {
                if showEmailConfirmation {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture { 
                                withAnimation(.easeInOut(duration: 0.3)) { 
                                    showEmailConfirmation = false 
                                } 
                            }
                        EmailConfirmationSheet(
                            isPresented: $showEmailConfirmation,
                            subject: pendingEmailSubject,
                            onConfirm: {
                                openMailApp(subject: pendingEmailSubject)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showEmailConfirmation = false
                                }
                            }
                        )
                    }
                    .opacity(showEmailConfirmation ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showEmailConfirmation)
                }
            }
            
            // External link confirmation overlay
            ZStack {
                if showExternalLinkConfirmation {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture { 
                                withAnimation(.easeInOut(duration: 0.3)) { 
                                    showExternalLinkConfirmation = false 
                                } 
                            }
                        ExternalLinkConfirmationSheet(
                            isPresented: $showExternalLinkConfirmation,
                            linkTitle: pendingLinkTitle,
                            onConfirm: {
                                openExternalLink(url: pendingExternalURL)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showExternalLinkConfirmation = false
                                }
                            }
                        )
                    }
                    .opacity(showExternalLinkConfirmation ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showExternalLinkConfirmation)
                }
            }
            
            // Profile editor overlay
            ZStack {
                if showProfileEditor {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture { 
                                withAnimation(.easeInOut(duration: 0.3)) { 
                                    showProfileEditor = false 
                                } 
                            }
                        // Native profile editor is used instead
                    }
                    .opacity(showProfileEditor ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showProfileEditor)
                }
            }
        }
    }
    
    private func openMailApp(subject: String) {
        let email = "admin@shiftstudios.space"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(email)?subject=\(encodedSubject)"
        
        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func openExternalLink(url: String) {
        if let url = URL(string: url) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func showNativeProfileEditor() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let profileEditor = NativeProfileEditorViewController(
            currentName: userManager.userName,
            onSave: { newName in
                DispatchQueue.main.async {
                    UserManager.shared.updateName(newName)
                }
            }
        )
        
        let navController = UINavigationController(rootViewController: profileEditor)
        navController.modalPresentationStyle = .pageSheet
        
        if let presentedVC = window.rootViewController?.presentedViewController {
            presentedVC.present(navController, animated: true)
        } else {
            window.rootViewController?.present(navController, animated: true)
        }
    }
}

// MARK: - Email Confirmation Sheet
struct EmailConfirmationSheet: View {
    @Binding var isPresented: Bool
    let subject: String
    let onConfirm: () -> Void
    @State private var noPressed = false
    @State private var yesPressed = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { 
                    withAnimation(.easeInOut(duration: 0.3)) { 
                        isPresented = false 
                    } 
                }
            VStack(spacing: 24) {
                Text("Open Mail App?")
                    .font(.system(size: 28, weight: .light, design: .default))
                    .foregroundColor(.black)
                
                Text("This will take you outside this app to your Mail app.")
                    .font(.system(size: 16, weight: .light, design: .default))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                HStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Button(action: {
                            Constants.Haptics.primaryButtonPress()
                            noPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                withAnimation(.easeInOut(duration: 0.3)) { 
                                    isPresented = false 
                                    noPressed = false
                                }
                            }
                        }) {
                            Text("No")
                                .font(.system(size: 18, weight: .light, design: .default))
                                .foregroundColor(.black)
                                .opacity(noPressed ? 0.5 : 1.0)
                        }
                        .animation(.easeInOut(duration: 0.15), value: noPressed)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            Constants.Haptics.primaryButtonPress()
                            yesPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                onConfirm()
                                yesPressed = false
                            }
                        }) {
                            Text("Yes")
                                .font(.system(size: 18, weight: .light, design: .default))
                                .foregroundColor(.black)
                                .opacity(yesPressed ? 0.5 : 1.0)
                        }
                        .animation(.easeInOut(duration: 0.15), value: yesPressed)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 6)
            }
            .padding(24)
            .background(Color(red: 0.96, green: 0.94, blue: 0.91))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 4)
            .frame(minWidth: 260, maxWidth: 300)
        }
    }
}







// MARK: - External Link Confirmation Sheet
struct ExternalLinkConfirmationSheet: View {
    @Binding var isPresented: Bool
    let linkTitle: String
    let onConfirm: () -> Void
    @State private var noPressed = false
    @State private var yesPressed = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { 
                    withAnimation(.easeInOut(duration: 0.3)) { 
                        isPresented = false 
                    } 
                }
            VStack(spacing: 24) {
                Text("Open \(linkTitle)?")
                    .font(.system(size: 28, weight: .light, design: .default))
                    .foregroundColor(.black)
                
                Text("This will take you outside this app to view the \(linkTitle.lowercased()) in your browser.")
                    .font(.system(size: 16, weight: .light, design: .default))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                HStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Button(action: {
                            Constants.Haptics.primaryButtonPress()
                            noPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                withAnimation(.easeInOut(duration: 0.3)) { 
                                    isPresented = false 
                                    noPressed = false
                                }
                            }
                        }) {
                            Text("No")
                                .font(.system(size: 18, weight: .light, design: .default))
                                .foregroundColor(.black)
                                .opacity(noPressed ? 0.5 : 1.0)
                        }
                        .animation(.easeInOut(duration: 0.15), value: noPressed)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            Constants.Haptics.primaryButtonPress()
                            yesPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                onConfirm()
                                yesPressed = false
                            }
                        }) {
                            Text("Yes")
                                .font(.system(size: 18, weight: .light, design: .default))
                                .foregroundColor(.black)
                                .opacity(yesPressed ? 0.5 : 1.0)
                        }
                        .animation(.easeInOut(duration: 0.15), value: yesPressed)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 6)
            }
            .padding(24)
            .background(Color(red: 0.96, green: 0.94, blue: 0.91))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 4)
            .frame(minWidth: 260, maxWidth: 320)
        }
    }
}

// MARK: - Profile Image View
struct ProfileImageView: View {
    let size: CGFloat
    @State private var profileImage: UIImage?
    
    var body: some View {
        ZStack {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
        }
        .onAppear {
            loadProfileImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileImageChanged"))) { _ in
            loadProfileImage()
        }
    }
    
    private func loadProfileImage() {
        guard let imageData = UserDefaults.standard.data(forKey: "userProfileImageData"),
              let image = UIImage(data: imageData) else {
            profileImage = nil
            return
        }
        profileImage = image
    }
}

// MARK: - Native UIKit Profile Editor (Optimized for Zero Lag)
class NativeProfileEditorViewController: UIViewController {
    private let currentName: String
    private let onSave: (String) -> Void
    private var nameTextField: UITextField!
    private var profileImageView: UIView!
    private var profileImageButton: UIButton!
    
    // Pre-warm keyboard system
    private static var isKeyboardPreWarmed = false
    
    init(currentName: String, onSave: @escaping (String) -> Void) {
        self.currentName = currentName
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
        
        // Pre-warm keyboard on first use
        Self.preWarmKeyboard()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Keyboard Pre-warming
    private static func preWarmKeyboard() {
        guard !isKeyboardPreWarmed else { return }
        isKeyboardPreWarmed = true
        
        DispatchQueue.main.async {
            // Create a temporary text field to initialize the keyboard system
            let tempTextField = UITextField()
            tempTextField.autocorrectionType = .no
            tempTextField.autocapitalizationType = .words
            tempTextField.keyboardType = .default
            
            // Add to a temporary window
            let tempWindow = UIWindow(frame: .zero)
            tempWindow.addSubview(tempTextField)
            tempTextField.becomeFirstResponder()
            
            // Clean up immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                tempTextField.resignFirstResponder()
                tempTextField.removeFromSuperview()
                tempWindow.isHidden = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardNotifications()
        loadExistingProfileImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Pre-focus just before appearing for instant response
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.nameTextField.becomeFirstResponder()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Keyboard Management
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        
        // Adjust content inset for keyboard
        if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset.bottom = keyboardHeight
            scrollView.scrollIndicatorInsets.bottom = keyboardHeight
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset.bottom = 0
            scrollView.scrollIndicatorInsets.bottom = 0
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.94, blue: 0.91, alpha: 1.0)
        
        // Hide default navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Create custom header section
        let headerView = UIView()
        headerView.backgroundColor = UIColor(red: 0.96, green: 0.94, blue: 0.91, alpha: 1.0)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        // Cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .light)
        cancelButton.setTitleColor(UIColor.black, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(cancelButton)
        
        // Save button
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("save", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .light)
        saveButton.setTitleColor(UIColor.black, for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(saveButton)
        
        // Center title
        let titleLabel = UILabel()
        titleLabel.text = "edit profile"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .light)
        titleLabel.textColor = UIColor.black
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        // Header divider
        let headerDivider = UIView()
        headerDivider.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        headerDivider.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerDivider)
        

        
        // Create scroll view like other pages
        let scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor(red: 0.96, green: 0.94, blue: 0.91, alpha: 1.0)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Centered Profile Section with Photo Picker
        profileImageView = UIView()
        profileImageView.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        profileImageView.layer.cornerRadius = 60
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = UIColor.black.cgColor
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Make profile image view tappable
        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(profileTapGesture)
        profileImageView.isUserInteractionEnabled = true
        
        // Camera/Edit Icon Button
        let cameraIconButton = UIButton(type: .system)
        cameraIconButton.backgroundColor = UIColor.white
        cameraIconButton.layer.cornerRadius = 15 // 30x30 button, so radius is 15
        cameraIconButton.layer.borderWidth = 1
        cameraIconButton.layer.borderColor = UIColor.darkGray.cgColor
        cameraIconButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        cameraIconButton.tintColor = UIColor.black
        cameraIconButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        cameraIconButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add divider after profile section
        let divider1 = UIView()
        divider1.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        divider1.translatesAutoresizingMaskIntoConstraints = false
        
        // Name section
        let nameLabel = UILabel()
        nameLabel.text = "NAME"
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .light)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.6)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // OPTIMIZED Text Field - Pre-configured for maximum performance
        nameTextField = UITextField()
        nameTextField.text = currentName
        nameTextField.placeholder = "Enter name"
        nameTextField.font = UIFont.systemFont(ofSize: 18, weight: .light)
        nameTextField.textColor = UIColor.black
        nameTextField.backgroundColor = UIColor.white
        nameTextField.layer.cornerRadius = 8
        nameTextField.layer.borderWidth = 1
        nameTextField.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        
        // Optimized padding views (reuse)
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        nameTextField.leftView = leftPadding
        nameTextField.leftViewMode = .always
        nameTextField.rightView = rightPadding
        nameTextField.rightViewMode = .always
        
        // Keyboard optimizations
        nameTextField.autocorrectionType = .no
        nameTextField.autocapitalizationType = .words
        nameTextField.returnKeyType = .done
        nameTextField.enablesReturnKeyAutomatically = true
        nameTextField.clearButtonMode = .whileEditing
        nameTextField.smartDashesType = .no
        nameTextField.smartQuotesType = .no
        nameTextField.spellCheckingType = .no
        
        nameTextField.delegate = self
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add divider after name section
        let divider2 = UIView()
        divider2.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        divider2.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(profileImageView)
        contentView.addSubview(cameraIconButton)
        contentView.addSubview(divider1)
        contentView.addSubview(nameLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(divider2)
        
        // Layout
        NSLayoutConstraint.activate([
            // Header layout
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            cancelButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            saveButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            saveButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),
            
            headerDivider.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 12),
            headerDivider.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 0.5),
            headerDivider.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            // Scroll view layout
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Centered profile section
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Camera icon button (bottom-right of profile image, more inset)
            cameraIconButton.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: -5),
            cameraIconButton.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: -5),
            cameraIconButton.widthAnchor.constraint(equalToConstant: 30),
            cameraIconButton.heightAnchor.constraint(equalToConstant: 30),
            
            divider1.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 40),
            divider1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            divider1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            divider1.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Name section
            nameLabel.topAnchor.constraint(equalTo: divider1.bottomAnchor, constant: 32),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            divider2.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 32),
            divider2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            divider2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            divider2.heightAnchor.constraint(equalToConstant: 0.5),
            divider2.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -60)
        ])
    }
    
    @objc private func cancelTapped() {
        nameTextField.resignFirstResponder()
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let newName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !newName.isEmpty {
            // Use UserManager for global state
            UserManager.shared.updateName(newName)
            onSave(newName)
        }
        nameTextField.resignFirstResponder()
        dismiss(animated: true)
    }
    
    @objc private func cameraButtonTapped() {
        Constants.Haptics.buttonPress()
        checkPhotoPermissionAndPresentPicker()
    }
    
    @objc private func profileImageTapped() {
        Constants.Haptics.buttonPress()
        checkPhotoPermissionAndPresentPicker()
    }
    
    private func checkPhotoPermissionAndPresentPicker() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            // Permission already granted
            presentPhotoPicker()
        case .denied, .restricted:
            // Permission denied, show settings alert
            showPermissionDeniedAlert()
        case .notDetermined:
            // Ask for permission
            showPermissionRequestAlert()
        @unknown default:
            showPermissionRequestAlert()
        }
    }
    
    private func showPermissionRequestAlert() {
        let alert = UIAlertController(
            title: "Access Photo Library",
            message: "Shift needs access to your photo library to let you choose a profile picture. Would you like to grant access?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Allow Access", style: .default) { _ in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .limited:
                        self.presentPhotoPicker()
                    case .denied, .restricted:
                        self.showPermissionDeniedAlert()
                    case .notDetermined:
                        break
                    @unknown default:
                        break
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Photo Access Denied",
            message: "To choose a profile picture, please enable photo access in Settings > Privacy & Security > Photos > Shift.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func loadExistingProfileImage() {
        guard let imageData = UserDefaults.standard.data(forKey: "userProfileImageData"),
              let image = UIImage(data: imageData) else { return }
        
        updateProfileImage(image)
    }
}

extension NativeProfileEditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveTapped()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Provide haptic feedback when editing begins
        Constants.Haptics.buttonPress()
    }
}

// MARK: - Photo Picker Delegate
extension NativeProfileEditorViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                guard let self = self,
                      let image = object as? UIImage else { return }
                
                self.updateProfileImage(image)
                Constants.Haptics.photoSelected()
            }
        }
    }
    
    private func updateProfileImage(_ image: UIImage) {
        // Create a circular image view
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 60
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove any existing image views
        profileImageView.subviews.forEach { $0.removeFromSuperview() }
        
        // Add the new image
        profileImageView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor)
        ])
        
        // Save image to UserDefaults as Data
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: "userProfileImageData")
            // Notify other views to update profile image
            NotificationCenter.default.post(name: NSNotification.Name("ProfileImageChanged"), object: nil)
        }
    }
}

#Preview {
    HomeView()
} 
