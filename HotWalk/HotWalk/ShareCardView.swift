import SwiftUI

struct ShareCardView: View {
    let steps: Int
    let goalPercentage: Int
    let message: String
    let dailyGoal: Int
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Hot Girl Steps")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Progress Ring
            ZStack {
                // Background Ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Progress Ring
                Circle()
                    .trim(from: 0, to: CGFloat(min(goalPercentage, 100)) / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.8),
                                Color.purple.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                // Steps Count
                VStack(spacing: 4) {
                    Text("\(steps)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("steps")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(goalPercentage)% of \(dailyGoal)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Motivational Message
            Text(message)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            
            // Footer
            Text("hotgirlwalk.app")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(30)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 44/255, green: 8/255, blue: 52/255),
                    Color.purple.opacity(0.3),
                    Color(hue: 0.83, saturation: 0.3, brightness: 0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ShareCardView(
        steps: 7500,
        goalPercentage: 75,
        message: "You're crushing it! Keep those hot girl steps coming! 🔥",
        dailyGoal: 10000
    )
    .frame(width: 350, height: 500)
} 