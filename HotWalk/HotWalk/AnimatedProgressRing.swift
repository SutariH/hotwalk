import SwiftUI

struct Sparkle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
    var wobbleOffset: CGPoint
    var color: Color
    var delay: Double
    var duration: Double
    var movementDirection: CGPoint
    var movementSpeed: Double
    var pulsePhase: Double
    var pulseSpeed: Double
}

struct AnimatedProgressRing: View {
    let progress: Double
    let steps: Int
    @State private var sparkles: [Sparkle] = []
    @State private var ringScale: CGFloat = 1.0
    @State private var ringGlowOpacity: Double = 0.3
    @State private var lastProgress: Double = 0
    @State private var celebrationActive: Bool = false
    @State private var animationPhase: Double = 0
    @State private var sparkleTimer: Timer?
    @State private var movementTimer: Timer?
    @State private var pulseTimer: Timer?
    
    private let baseRadius: CGFloat = 100
    private let ringSize: CGFloat = 250
    private let celebrationColors: [Color] = [.white, .yellow, .pink, .purple]
    
    private func generateSparkles(count: Int, isCelebration: Bool = false) -> [Sparkle] {
        var newSparkles: [Sparkle] = []
        let angleStep = 360.0 / Double(count)
        
        for i in 0..<count {
            let angle = Double(i) * angleStep
            let radius = isCelebration ? baseRadius * 1.5 : baseRadius
            let baseX = cos(angle * .pi / 180) * radius
            let baseY = sin(angle * .pi / 180) * radius
            
            // Generate random movement direction
            let randomAngle = Double.random(in: 0...360) * .pi / 180
            let movementDirection = CGPoint(
                x: cos(randomAngle),
                y: sin(randomAngle)
            )
            
            let randomColor = isCelebration ? 
                celebrationColors[Int.random(in: 0..<celebrationColors.count)] :
                .white
            
            newSparkles.append(Sparkle(
                position: CGPoint(x: baseX, y: baseY),
                scale: isCelebration ? 1.5 : 1.0,
                opacity: isCelebration ? 1.0 : 0.8,
                rotation: angle,
                wobbleOffset: CGPoint(
                    x: CGFloat.random(in: -5...5),
                    y: CGFloat.random(in: -5...5)
                ),
                color: randomColor,
                delay: Double.random(in: 0...1),
                duration: Double.random(in: 1.5...2.5),
                movementDirection: movementDirection,
                movementSpeed: Double.random(in: 0.5...2.0),
                pulsePhase: Double.random(in: 0...360),
                pulseSpeed: Double.random(in: 1.0...3.0)
            ))
        }
        return newSparkles
    }
    
    private func updateSparkles() {
        let count = progress >= 1.0 ? 24 : (progress >= 0.75 ? 16 : 8)
        sparkles = generateSparkles(count: count, isCelebration: progress >= 1.0)
    }
    
    private func startCelebration() {
        celebrationActive = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            ringScale = 1.1
        }
        
        // Reset after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            celebrationActive = false
            withAnimation(.easeOut(duration: 0.5)) {
                ringScale = 1.0
            }
        }
    }
    
    private func updateSparklePositions() {
        let maxRadius = progress >= 1.0 ? baseRadius * 1.5 : baseRadius
        let bounceFactor: CGFloat = 0.8
        
        for i in 0..<sparkles.count {
            var sparkle = sparkles[i]
            
            // Update position based on movement direction
            sparkle.position.x += sparkle.movementDirection.x * sparkle.movementSpeed
            sparkle.position.y += sparkle.movementDirection.y * sparkle.movementSpeed
            
            // Calculate distance from center
            let distance = sqrt(pow(sparkle.position.x, 2) + pow(sparkle.position.y, 2))
            
            // Bounce off the ring boundary
            if distance > maxRadius {
                let angle = atan2(sparkle.position.y, sparkle.position.x)
                sparkle.position.x = cos(angle) * maxRadius * bounceFactor
                sparkle.position.y = sin(angle) * maxRadius * bounceFactor
                
                // Reflect movement direction
                let normalX = sparkle.position.x / distance
                let normalY = sparkle.position.y / distance
                let dot = sparkle.movementDirection.x * normalX + sparkle.movementDirection.y * normalY
                sparkle.movementDirection.x -= 2 * dot * normalX
                sparkle.movementDirection.y -= 2 * dot * normalY
                
                // Normalize direction
                let length = sqrt(pow(sparkle.movementDirection.x, 2) + pow(sparkle.movementDirection.y, 2))
                sparkle.movementDirection.x /= length
                sparkle.movementDirection.y /= length
            }
            
            sparkles[i] = sparkle
        }
    }
    
    private func updatePulseEffects() {
        for i in 0..<sparkles.count {
            var sparkle = sparkles[i]
            sparkle.pulsePhase += sparkle.pulseSpeed
            if sparkle.pulsePhase >= 360 {
                sparkle.pulsePhase = 0
            }
            sparkles[i] = sparkle
        }
    }
    
    var body: some View {
        ZStack {
            // Background ring with glow
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(ringGlowOpacity),
                            Color.purple.opacity(ringGlowOpacity * 0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 20
                )
                .frame(width: ringSize, height: ringSize)
                .scaleEffect(ringScale)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.8),
                            Color.pink.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Sparkles
            ForEach(sparkles) { sparkle in
                Circle()
                    .fill(sparkle.color)
                    .frame(width: 6, height: 6)
                    .opacity(sparkle.opacity * (0.7 + 0.3 * sin(sparkle.pulsePhase * .pi / 180)))
                    .scaleEffect(sparkle.scale * (0.8 + 0.2 * sin(sparkle.pulsePhase * .pi / 180)))
                    .offset(
                        x: sparkle.position.x + sparkle.wobbleOffset.x,
                        y: sparkle.position.y + sparkle.wobbleOffset.y
                    )
                    .rotationEffect(.degrees(sparkle.rotation + animationPhase))
                    .animation(
                        .linear(duration: sparkle.duration)
                        .repeatForever(autoreverses: false)
                        .delay(sparkle.delay),
                        value: animationPhase
                    )
            }
            
            // Step count and label
            VStack(spacing: 4) {
                Text("\(steps)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                
                Text("steps")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onAppear {
            updateSparkles()
            startGlowAnimation()
            startRotationAnimation()
            startMovementAnimation()
            startPulseAnimation()
        }
        .onDisappear {
            sparkleTimer?.invalidate()
            movementTimer?.invalidate()
            pulseTimer?.invalidate()
            sparkleTimer = nil
            movementTimer = nil
            pulseTimer = nil
        }
        .onChange(of: progress) { newProgress in
            if newProgress >= 1.0 && lastProgress < 1.0 {
                startCelebration()
            }
            lastProgress = newProgress
            updateSparkles()
            startRotationAnimation()
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            ringGlowOpacity = progress >= 0.75 ? 0.6 : 0.3
        }
    }
    
    private func startRotationAnimation() {
        sparkleTimer?.invalidate()
        
        let duration = progress >= 1.0 ? 2.0 : (progress >= 0.75 ? 4.0 : 12.0)
        let step = 360.0 / (duration * 60) // 60 updates per second
        
        sparkleTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            animationPhase += step
            if animationPhase >= 360 {
                animationPhase = 0
            }
        }
    }
    
    private func startMovementAnimation() {
        movementTimer?.invalidate()
        movementTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateSparklePositions()
        }
    }
    
    private func startPulseAnimation() {
        pulseTimer?.invalidate()
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updatePulseEffects()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("50% Progress")
            .font(.headline)
        AnimatedProgressRing(progress: 0.5, steps: 5000)
            .frame(width: 250, height: 250)
        
        Text("90% Progress")
            .font(.headline)
        AnimatedProgressRing(progress: 0.9, steps: 9000)
            .frame(width: 250, height: 250)
        
        Text("100% Progress")
            .font(.headline)
        AnimatedProgressRing(progress: 1.0, steps: 10000)
            .frame(width: 250, height: 250)
    }
    .preferredColorScheme(.dark)
    .padding()
} 

