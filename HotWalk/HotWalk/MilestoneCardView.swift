import SwiftUI

struct MilestoneCardView: View {
    let milestone: MilestoneType
    let onClose: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            // Milestone Icon
            Text(milestone.icon)
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding()
                .background(
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 100, height: 100)
                )
            
            // Title
            Text(milestone.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Description
            Text(milestone.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Share Button
            Button(action: onShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Achievement")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 10)
        )
        .padding()
    }
}

#Preview {
    MilestoneCardView(
        milestone: .threeDayStreak,
        onClose: {},
        onShare: {}
    )
} 