import SwiftUI

struct FocusShieldView: View {
    var appName: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()  // Force a pure black background

            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)

                Text(appName.uppercased())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("This app is blocked during focus mode.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Button("Back to Home") {
                    ShieldPresenter.shared.hide()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .padding()
        }
    }
}
