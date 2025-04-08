import SwiftUI

struct MilestoneCardView: View {
    let milestone: MilestoneType
    let onDismiss: () -> Void
    let onShare: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with icon
            HStack {
                Text(milestone.icon)
                    .font(.system(size: 40))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                Text(milestone.rawValue)
                    .font(.system(size: 28, weight: .bold))
            }
            .padding(.top, 30)
            
            // Message
            Text(milestone.message)
                .font(.system(size: 17, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // App name
            Text("Hot Walk")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            // Buttons
            HStack(spacing: 20) {
                Button(action: onDismiss) {
                    Text("Close")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 100)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                
                Button(action: onShare) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 100)
                    .padding(.vertical, 10)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.bottom, 30)
        }
        .frame(width: 300)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .onAppear {
            isAnimating = true
        }
    }
}

// Preview provider
struct MilestoneCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3).edgesIgnoringSafeArea(.all)
            
            MilestoneCardView(
                milestone: .threeDayStreak,
                onDismiss: {},
                onShare: {}
            )
        }
    }
} 