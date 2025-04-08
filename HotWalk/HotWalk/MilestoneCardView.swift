import SwiftUI

struct MilestoneCardView: View {
    let milestone: MilestoneType
    let onDismiss: () -> Void
    let onShare: () -> Void
    
    @State private var isAnimating = false
    @State private var sparkleOpacity = 0.0
    
    var body: some View {
        VStack(spacing: 25) {
            // Header with icon
            VStack(spacing: 10) {
                Text(milestone.icon)
                    .font(.system(size: 60))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                    .accessibilityLabel("Milestone icon: \(milestone.icon)")
                
                Text(milestone.rawValue)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.top, 30)
            
            // Message
            Text(milestone.message)
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
                .accessibilityLabel(milestone.message)
            
            // Date and step count
            VStack(spacing: 5) {
                Text(getCurrentDate())
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("hotwalk.app")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.top, 10)
            
            // Tagline
            Text("Built different. Walked different.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .italic()
                .padding(.top, 5)
            
            // Hot Girl Verified Badge
            HStack {
                Text("HOT GIRL VERIFIED")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.pink)
                    .cornerRadius(12)
                
                Text("💅")
                    .font(.system(size: 16))
            }
            .padding(.top, 10)
            
            Spacer()
            
            // Buttons
            HStack(spacing: 20) {
                Button(action: onDismiss) {
                    Text("Close")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 100)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .accessibilityLabel("Close milestone card")
                
                Button(action: onShare) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Flex This")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 120)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .foregroundColor(.purple)
                    .cornerRadius(10)
                }
                .accessibilityLabel("Share milestone: \(milestone.rawValue)")
            }
            .padding(.bottom, 30)
        }
        .frame(width: 320, height: 500)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8)]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
        )
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
        .overlay(
            // Sparkle effects
            ZStack {
                ForEach(0..<5) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .opacity(sparkleOpacity)
                        .offset(x: CGFloat.random(in: -120...120), y: CGFloat.random(in: -200...200))
                        .rotationEffect(Angle(degrees: Double.random(in: 0...360)))
                }
            }
        )
        .onAppear {
            isAnimating = true
            
            // Animate sparkles
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                sparkleOpacity = 0.7
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Milestone achieved: \(milestone.rawValue). \(milestone.message)")
    }
    
    private func getCurrentDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: Date())
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