import SwiftUI

struct MilestoneCardView: View {
    let milestone: MilestoneType
    let onClose: () -> Void
    let onShare: () -> Void
    
    // Share-specific taglines
    private let shareTaglines = [
        "🔥 Crushing goals like a boss!",
        "✨ Hot girl walking to success!",
        "💪 Steps don't lie, and neither do I!",
        "🌟 Making moves, breaking records!",
        "🚶‍♀️ Walking my way to greatness!",
        "💃 Slaying the step game!",
        "🏆 Another milestone unlocked!",
        "🎯 Goals? Crushed them!",
        "💫 Hot girl energy activated!",
        "👑 Queen of the sidewalk!"
    ]
    
    // Random tagline generator
    @State private var currentTagline: String
    
    init(milestone: MilestoneType, onClose: @escaping () -> Void, onShare: @escaping () -> Void) {
        self.milestone = milestone
        self.onClose = onClose
        self.onShare = onShare
        _currentTagline = State(initialValue: shareTaglines.randomElement() ?? "🔥 Crushing goals like a boss!")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Milestone Icon with Sparkle Ring
            ZStack {
                // Background Ring
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.pink.opacity(0.3),
                                Color.purple.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 120, height: 120)
                
                // Sparkle Ring
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.pink.opacity(0.6),
                                Color.purple.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(45))
                
                // Milestone Icon
                Text(milestone.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.pink.opacity(0.8),
                                        Color.purple.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                    )
            }
            .padding(.vertical, 20)
            
            // Title
            Text(milestone.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            
            // Description
            Text(milestone.description)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
            
            // Share Message
            Text(currentTagline)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
            
            // App Logo
            Image("HotGirlStepsLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .padding(.vertical, 10)
            
            // Download Prompt
            Text("Track your steps at hotgirlsteps.com")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 10)
            
            // Share Button
            Button(action: onShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Achievement")
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.pink.opacity(0.8),
                            Color.purple.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 44/255, green: 8/255, blue: 52/255),
                    Color.purple.opacity(0.8),
                    Color.pink.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding()
        .frame(width: 350, height: 600) // Adjusted height for new content
    }
}

#Preview {
    MilestoneCardView(
        milestone: .threeDayStreak,
        onClose: {},
        onShare: {}
    )
} 
