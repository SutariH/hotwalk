import SwiftUI

// MARK: - Progress Animation States
enum ProgressAnimationState {
    case early(progress: Double)      // 0-74%
    case nearing(progress: Double)    // 75-99%
    case completed(progress: Double)  // 100%+
    
    static func fromProgress(_ progress: Double) -> ProgressAnimationState {
        if progress >= 1.0 {
            return .completed(progress: progress)
        } else if progress >= 0.75 {
            return .nearing(progress: progress)
        } else {
            return .early(progress: progress)
        }
    }
}

// MARK: - Sparkle View
struct SparkleView: View {
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
    let rotation: Double
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundColor(.white)
            .opacity(opacity)
            .position(position)
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Animated Progress Ring
struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    @State private var sparkles: [(id: UUID, position: CGPoint, size: CGFloat, opacity: Double, rotation: Double)] = []
    @State private var ringGlowOpacity: Double = 0.0
    @State private var hasCompletedAnimation: Bool = false
    
    private let animationState: ProgressAnimationState
    
    init(progress: Double, lineWidth: CGFloat = 20, size: CGFloat = 300) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.animationState = ProgressAnimationState.fromProgress(progress)
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.pink, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Glow effect for nearing completion
            if case .nearing = animationState {
                Circle()
                    .stroke(Color.pink.opacity(0.3), lineWidth: lineWidth + 10)
                    .blur(radius: 10)
                    .opacity(ringGlowOpacity)
            }
            
            // Sparkles
            ForEach(sparkles, id: \.id) { sparkle in
                SparkleView(
                    position: sparkle.position,
                    size: sparkle.size,
                    opacity: sparkle.opacity,
                    rotation: sparkle.rotation
                )
            }
        }
        .frame(width: size, height: size)
        .onChange(of: progress) { newProgress in
            updateAnimationState(for: newProgress)
        }
        .onAppear {
            updateAnimationState(for: progress)
        }
    }
    
    private func updateAnimationState(for progress: Double) {
        let newState = ProgressAnimationState.fromProgress(progress)
        
        // Clear existing sparkles
        sparkles.removeAll()
        
        switch newState {
        case .early:
            // Early stage: few, slow-moving sparkles
            addSparkles(count: 3, speed: 10, size: 15, opacity: 0.4)
            
        case .nearing:
            // Nearing completion: more active sparkles with pulsing
            addSparkles(count: 6, speed: 8, size: 20, opacity: 0.6)
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                ringGlowOpacity = 0.5
            }
            
        case .completed:
            // Completion: celebration animation (only once)
            if !hasCompletedAnimation {
                hasCompletedAnimation = true
                celebrateCompletion()
            }
        }
    }
    
    private func addSparkles(count: Int, speed: Double, size: CGFloat, opacity: Double) {
        for _ in 0..<count {
            let angle = Double.random(in: 0..<360)
            let radius = self.size / 2 - lineWidth
            let x = cos(angle * .pi / 180) * radius + self.size / 2
            let y = sin(angle * .pi / 180) * radius + self.size / 2
            
            let sparkle = (
                id: UUID(),
                position: CGPoint(x: x, y: y),
                size: size,
                opacity: opacity,
                rotation: Double.random(in: 0..<360)
            )
            
            sparkles.append(sparkle)
            
            // Animate the sparkle
            withAnimation(
                .linear(duration: speed)
                .repeatForever(autoreverses: true)
            ) {
                // Update the sparkle's position in a circular motion
                let newAngle = angle + 30
                let newX = cos(newAngle * .pi / 180) * radius + self.size / 2
                let newY = sin(newAngle * .pi / 180) * radius + self.size / 2
                
                if let index = sparkles.firstIndex(where: { $0.id == sparkle.id }) {
                    sparkles[index].position = CGPoint(x: newX, y: newY)
                    sparkles[index].rotation += 180
                }
            }
        }
    }
    
    private func celebrateCompletion() {
        // Add burst of sparkles
        addSparkles(count: 12, speed: 5, size: 25, opacity: 0.8)
        
        // Add glowing effect
        withAnimation(.easeInOut(duration: 1.0)) {
            ringGlowOpacity = 0.7
        }
        
        // Reset glow after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                ringGlowOpacity = 0.0
            }
        }
    }
}

// MARK: - Preview
struct AnimatedProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                AnimatedProgressRing(progress: 0.3)
                AnimatedProgressRing(progress: 0.8)
                AnimatedProgressRing(progress: 1.0)
            }
        }
    }
} 