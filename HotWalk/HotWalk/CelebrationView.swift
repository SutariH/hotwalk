import SwiftUI

struct CelebrationView: View {
    @State private var sparkles: [Sparkle] = []
    @State private var isVisible = false
    let onComplete: () -> Void
    
    struct Sparkle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var scale: CGFloat
        var rotation: Double
        var opacity: Double
        var emoji: String
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissCelebration()
                }
            
            // Sparkle particles
            ForEach(sparkles) { sparkle in
                Text(sparkle.emoji)
                    .font(.system(size: 24 * sparkle.scale))
                    .position(sparkle.position)
                    .rotationEffect(.degrees(sparkle.rotation))
                    .opacity(sparkle.opacity)
            }
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private func startCelebration() {
        // Create initial sparkles
        sparkles = (0..<30).map { _ in
            createSparkle()
        }
        
        // Animate in
        withAnimation(.easeIn(duration: 0.5)) {
            isVisible = true
        }
        
        // Animate sparkles
        animateSparkles()
        
        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            dismissCelebration()
        }
    }
    
    private func createSparkle() -> Sparkle {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let emojis = ["✨", "🌟", "💫", "⭐️", "💥", "💃"]
        
        return Sparkle(
            position: CGPoint(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: 0...screenHeight)
            ),
            scale: CGFloat.random(in: 0.5...1.5),
            rotation: Double.random(in: 0...360),
            opacity: 0,
            emoji: emojis.randomElement() ?? "✨"
        )
    }
    
    private func animateSparkles() {
        for index in sparkles.indices {
            let duration = Double.random(in: 1.0...2.0)
            let delay = Double.random(in: 0...0.5)
            
            withAnimation(
                .easeInOut(duration: duration)
                .delay(delay)
                .repeatCount(1, autoreverses: true)
            ) {
                sparkles[index].opacity = 1
                sparkles[index].scale *= 1.2
                sparkles[index].rotation += 360
                
                // Move sparkle
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                sparkles[index].position = CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                )
            }
            
            // Fade out
            withAnimation(.easeOut(duration: 0.5).delay(duration + delay)) {
                sparkles[index].opacity = 0
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.5)) {
            isVisible = false
        }
        onComplete()
    }
}

// Preview provider
struct CelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        CelebrationView(onComplete: {})
    }
} 