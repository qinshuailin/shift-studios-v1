import SwiftUI

struct NotificationView: View {
    let message: String
    let type: NotificationType
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.white)
                .padding(.leading, 16)
            
            Text(message)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
                .padding(.vertical, 12)
            
            Spacer()
        }
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private var iconName: String {
        switch type {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch type {
        case .success:
            return Color.green
        case .warning:
            return Color.orange
        case .error:
            return Color.red
        }
    }
}
