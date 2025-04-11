import SwiftUI

struct CelebrationView: View {
    @State private var sparkles: [Sparkle] = []
    @State private var isVisible = false
    @State private var explosionPhase = 0 // Unused: Not used in current implementation
    let onComplete: () -> Void
    
    struct Sparkle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var scale: CGFloat
        var rotation: Double
        var opacity: Double
        var emoji: String
        var velocity: CGPoint
        var color: Color
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background with glow effect
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.4),
                    Color.black.opacity(0.6)
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                dismissCelebration()
            }
            
            // Sparkle particles
            ForEach(sparkles) { sparkle in
                if sparkle.emoji.isEmpty {
                    // Custom sparkle shape
                    Circle()
                        .fill(sparkle.color)
                        .frame(width: 8 * sparkle.scale, height: 8 * sparkle.scale)
                        .position(sparkle.position)
                        .rotationEffect(.degrees(sparkle.rotation))
                        .opacity(sparkle.opacity)
                } else {
                    // Emoji sparkle
                    Text(sparkle.emoji)
                        .font(.system(size: 24 * sparkle.scale))
                        .position(sparkle.position)
                        .rotationEffect(.degrees(sparkle.rotation))
                        .opacity(sparkle.opacity)
                }
            }
            
            // Celebration text
            VStack {
                Text("GOAL ACHIEVED!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .purple.opacity(0.8), radius: 10, x: 0, y: 0)
                    .padding(.bottom, 10)
                
                Text("You're on fire! 🔥")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .purple.opacity(0.8), radius: 5, x: 0, y: 0)
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.5)
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private func startCelebration() {
        // Animate in
        withAnimation(.easeIn(duration: 0.5)) {
            isVisible = true
        }
        
        // Start with initial sparkles
        createInitialSparkles()
        
        // Trigger explosion after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            explosionPhase = 1
            createExplosionSparkles()
        }
        
        // Transition to simmering state
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            explosionPhase = 2
            createSimmeringSparkles()
        }
        
        // Dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            dismissCelebration()
        }
    }
    
    private func createInitialSparkles() {
        // Create a few initial sparkles
        sparkles = (0..<20).map { _ in
            createSparkle(isExplosion: false, isSimmering: false)
        }
        
        // Animate initial sparkles
        animateSparkles(isExplosion: false, isSimmering: false)
    }
    
    private func createExplosionSparkles() {
        // Clear existing sparkles
        sparkles.removeAll()
        
        // Create explosion sparkles
        sparkles = (0..<100).map { _ in
            createSparkle(isExplosion: true, isSimmering: false)
        }
        
        // Animate explosion sparkles
        animateSparkles(isExplosion: true, isSimmering: false)
    }
    
    private func createSimmeringSparkles() {
        // Clear existing sparkles
        sparkles.removeAll()
        
        // Create simmering sparkles
        sparkles = (0..<40).map { _ in
            createSparkle(isExplosion: false, isSimmering: true)
        }
        
        // Animate simmering sparkles
        animateSparkles(isExplosion: false, isSimmering: true)
    }
    
    private func createSparkle(isExplosion: Bool, isSimmering: Bool) -> Sparkle {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let emojis = ["✨", "🌟", "💫", "⭐️", "💥", "💃", "🔥", "👑", "🚀", "💅"]
        let colors: [Color] = [.pink, .purple, .yellow, .orange, .white]
        
        // Start from center for burst effect
        let centerX = screenWidth / 2
        let centerY = screenHeight / 2
        
        // Random angle for velocity
        let angle = Double.random(in: 0...2 * .pi)
        let speed = isExplosion ? 
            Double.random(in: 5...15) : 
            (isSimmering ? Double.random(in: 1...3) : Double.random(in: 2...5))
        
        // For explosion, some sparkles will be colored dots instead of emojis
        let useEmoji = !isExplosion || Bool.random()
        
        return Sparkle(
            position: CGPoint(x: centerX, y: centerY),
            scale: isExplosion ? 
                CGFloat.random(in: 0.3...1.2) : 
                (isSimmering ? CGFloat.random(in: 0.5...1.0) : CGFloat.random(in: 0.5...1.5)),
            rotation: Double.random(in: 0...360),
            opacity: 0,
            emoji: useEmoji ? (emojis.randomElement() ?? "✨") : "",
            velocity: CGPoint(
                x: cos(angle) * speed,
                y: sin(angle) * speed
            ),
            color: colors.randomElement() ?? .white
        )
    }
    
    private func animateSparkles(isExplosion: Bool, isSimmering: Bool) {
        for index in sparkles.indices {
            let duration = isExplosion ? 
                Double.random(in: 0.8...1.5) : 
                (isSimmering ? Double.random(in: 2.0...4.0) : Double.random(in: 1.5...3.0))
            let delay = isExplosion ? 
                Double.random(in: 0...0.2) : 
                (isSimmering ? Double.random(in: 0...0.5) : Double.random(in: 0...0.5))
            
            // Initial burst animation
            withAnimation(
                .easeOut(duration: isExplosion ? 0.3 : 0.5)
                .delay(delay)
            ) {
                sparkles[index].opacity = 1
                sparkles[index].scale *= isExplosion ? 2.0 : 1.5
                
                // Move sparkle outward
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                let centerX = screenWidth / 2
                let centerY = screenHeight / 2
                
                let distance = isExplosion ? 
                    CGFloat.random(in: 100...400) : 
                    (isSimmering ? CGFloat.random(in: 50...200) : CGFloat.random(in: 100...300))
                let angle = atan2(
                    sparkles[index].velocity.y,
                    sparkles[index].velocity.x
                )
                
                sparkles[index].position = CGPoint(
                    x: centerX + cos(angle) * distance,
                    y: centerY + sin(angle) * distance
                )
            }
            
            // Floating animation
            withAnimation(
                .easeInOut(duration: duration)
                .delay(delay + (isExplosion ? 0.3 : 0.5))
                .repeatCount(isSimmering ? 3 : 1, autoreverses: true)
            ) {
                sparkles[index].scale *= 1.2
                sparkles[index].rotation += 360
                
                // Add some random movement
                let currentX = sparkles[index].position.x
                let currentY = sparkles[index].position.y
                
                sparkles[index].position = CGPoint(
                    x: currentX + CGFloat.random(in: -50...50),
                    y: currentY + CGFloat.random(in: -50...50)
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