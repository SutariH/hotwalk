import SwiftUI

struct AffirmationCardView: View {
    let affirmation: String
    @State private var sparkleScale: CGFloat = 1.0
    @State private var sparkleOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.9, green: 0.6, blue: 0.9),
                    Color(red: 0.7, green: 0.3, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(20)
            .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Sparkle effects
            ForEach(0..<5) { index in
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: CGFloat.random(in: -100...100),
                        y: CGFloat.random(in: -100...100)
                    )
                    .scaleEffect(sparkleScale)
                    .opacity(sparkleOpacity)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: sparkleScale
                    )
            }
            
            // Affirmation text
            Text(affirmation)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(30)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
        }
        .frame(width: 300, height: 200)
        .onAppear {
            withAnimation {
                sparkleScale = 1.2
                sparkleOpacity = 1.0
            }
        }
    }
} 