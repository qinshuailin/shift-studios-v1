import SwiftUI
import FamilyControls
import MessageUI

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
    @State private var userName: String = "sarah" // Replace with dynamic fetch if available
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
                            Text("hi \(userName)")
                                .font(.system(size: 40, weight: .light, design: .default))
                            Spacer()
                            Button(action: {
                                Constants.Haptics.primaryButtonPress()
                                showSettingsMenu = true
                            }) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 35, height: 35)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 1)
                                    )
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
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .contentShape(Rectangle())
                        .background(editAppsPressed ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.96, green: 0.94, blue: 0.91))
                        .animation(.easeInOut(duration: 0.15), value: editAppsPressed)
                    }
                    .buttonStyle(PlainButtonStyle())
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
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false 
                            }
                        }) {
                            Text("cancel")
                                .font(.system(size: 20, weight: .light, design: .default))
                        }
                        .padding(.top, 8)
                        .buttonStyle(FadeTextButtonStyle())
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
                            let total = hours * 60 + minutes
                            UserDefaults.standard.set(total, forKey: "dailyGoalMinutes")
                            statsManager.dailyGoal = total
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }) {
                            Text("save")
                                .font(.system(size: 20, weight: .light, design: .default))
                        }
                        .padding(.top, 8)
                        .buttonStyle(FadeTextButtonStyle())
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
    @State private var userName: String = "sarah"
    @State private var contactPressed = false
    @State private var suggestPressed = false
    @State private var privacyPressed = false
    @State private var termsPressed = false
    @State private var showEmailConfirmation = false
    @State private var pendingEmailSubject = ""
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
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 1)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userName)
                                    .font(.system(size: 24, weight: .light, design: .default))
                                    .foregroundColor(.black)
                                Text("tap to edit profile")
                                    .font(.system(size: 16, weight: .light, design: .default))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    
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
                            // Handle privacy policy action
                            withAnimation(.easeInOut(duration: 0.15)) {
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
                            // Handle terms of service action
                            withAnimation(.easeInOut(duration: 0.15)) {
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
}

// MARK: - Email Confirmation Sheet
struct EmailConfirmationSheet: View {
    @Binding var isPresented: Bool
    let subject: String
    let onConfirm: () -> Void
    
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
                            withAnimation(.easeInOut(duration: 0.3)) { 
                                isPresented = false 
                            }
                        }) {
                            Text("No")
                                .font(.system(size: 18, weight: .light, design: .default))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(FadeTextButtonStyle())
                    }
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            onConfirm()
                        }) {
                            Text("Yes")
                                .font(.system(size: 18, weight: .light, design: .default))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(FadeTextButtonStyle())
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



#Preview {
    HomeView()
} 
