import SwiftUI

struct HomeView: View {
    @State private var progressValue: Float = 0.5 // 50% progress
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Section 1
                VStack(alignment: .leading, spacing: 16) {
                    Text("hi sarah")
                        .font(.system(size: 48, weight: .light, design: .default))
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    Text("2h 43m")
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
                // Section 3
                HStack {
                    Text("Clock In")
                        .font(.system(size: 40, weight: .light, design: .default))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .padding(.vertical, 16)
                }
                .background(Color.clear)
                Divider()
                // Section 4
                HStack {
                    Text("Edit Apps")
                        .font(.system(size: 40, weight: .light, design: .default))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .padding(.vertical, 16)
                }
                .background(Color.clear)
                Divider()
                // Section 5
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Goal")
                        .font(.system(size: 40, weight: .light, design: .default))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .padding(.vertical, 16)
                    HStack(alignment: .center) {
                        Text("2h 30m")
                            .font(.system(size: 20, weight: .light, design: .default))
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .light, design: .default))
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 2)
                    ZStack(alignment: .leading) {
                        GeometryReader { geometry in
                            let totalWidth = geometry.size.width
                            let progress = CGFloat(progressValue)
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 2)
                                .frame(height: 16)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black)
                                .frame(width: totalWidth * progress, height: 16)
                        }
                        .frame(height: 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color.clear)
            }
            .padding(.top, 5)
            .padding(.bottom, 10) // This controls the bottom space of the page
            .foregroundColor(.black)
        }
        .background(Color(red: 0.96, green: 0.94, blue: 0.91))
    }
}

#Preview {
    HomeView()
} 
