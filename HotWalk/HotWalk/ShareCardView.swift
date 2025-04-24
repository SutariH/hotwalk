import SwiftUI

struct ShareCardView: View {
    let steps: Int
    let goalPercentage: Int
    let message: String
    let dailyGoal: Int
    let onClose: () -> Void
    let onShare: () -> Void
    
    // Sparkle positions
    private let sparklePositions: [(x: CGFloat, y: CGFloat, size: CGFloat, rotation: Double)] = [
        (x: 0.3, y: 0.2, size: 0.8, rotation: 15),
        (x: 0.7, y: 0.3, size: 1.0, rotation: -20),
        (x: 0.2, y: 0.7, size: 0.7, rotation: 30),
        (x: 0.8, y: 0.6, size: 0.9, rotation: -15)
    ]
    
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
                .frame(width: 44, height: 44)
            }
            .padding(.bottom, 4)
            
            // Progress Ring with Sparkle Effect
            ZStack {
                // Enhanced Glow Effect
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.pink.opacity(0.4),
                                Color.purple.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 15)
                
                // Static Sparkles
                ForEach(sparklePositions, id: \.x) { position in
                    Circle()
                        .fill(Color.white)
                        .frame(width: position.size * 4, height: position.size * 4)
                        .blur(radius: 1)
                        .opacity(0.8)
                        .offset(x: (position.x - 0.5) * 180, y: (position.y - 0.5) * 180)
                        .rotationEffect(.degrees(position.rotation))
                }
                
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
                        lineWidth: 12
                    )
                    .frame(width: 160, height: 160)
                
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
                        lineWidth: 6
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(45))
                
                // Progress Ring
                Circle()
                    .trim(from: 0, to: CGFloat(min(goalPercentage, 100)) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.pink.opacity(0.8),
                                Color.purple.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.pink.opacity(0.5), radius: 8, x: 0, y: 0)
                
                // Steps Count
                VStack(spacing: 4) {
                    Text("\(steps)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("steps")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(goalPercentage)% of \(dailyGoal)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 120, height: 120)
                .background(Color.clear)
            }
            .padding(.vertical, 16)
            
            // Title
            Text("Daily Progress")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                .padding(.bottom, 4)
            
            // Motivational Message
            Text(message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .padding(.bottom, 12)
            
            // App Logo
            Image("HotGirlStepsLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 50)
                .padding(.vertical, 8)
            
            // Download Prompt
            Text("Track your steps with hotgirlsteps.com")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 12)
            
            // Share Button
            Button(action: onShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Progress")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
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
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())
            .frame(minHeight: 44)
            .padding(.horizontal)
        }
        .padding(20)
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
        .frame(width: 320, height: 550)
    }
}

#Preview {
    ShareCardView(
        steps: 7500,
        goalPercentage: 75,
        message: "You're crushing it! Keep those hot girl steps coming! 🔥",
        dailyGoal: 10000,
        onClose: {},
        onShare: {}
    )
} 
