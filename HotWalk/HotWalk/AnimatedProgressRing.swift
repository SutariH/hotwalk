import SwiftUI

// Configuration struct for animation parameters
private struct RingConfig {
    static let ringSize: CGFloat = 250
    static let sparkleSize: CGFloat = 4
    static let sparkleCount: Int = 5
    
    // Progress thresholds
    static let slowThreshold: Double = 0.5
    static let mediumThreshold: Double = 0.75
    static let fastThreshold: Double = 1.0
    
    // Animation durations
    static let slowDuration: Double = 2.0
    static let mediumDuration: Double = 1.5
    static let fastDuration: Double = 1.0
    static let celebrationDuration: Double = 1.8
    
    // Ring radius for sparkle positioning
    static let ringRadius: CGFloat = ringSize / 2
    
    // Sparkle movement ranges
    static let slowRange: ClosedRange<CGFloat> = -40...40
    static let mediumRange: ClosedRange<CGFloat> = 0...120
    static let fastRange: ClosedRange<CGFloat> = -200...200
    static let celebrationRange: ClosedRange<CGFloat> = -150...150
    
    // Enhanced glow configurations
    static let slowGlow: Double = 0.3
    static let mediumGlow: Double = 0.6
    static let fastGlow: Double = 0.9
    static let celebrationGlow: Double = 1.0
    
    static let slowBlur: CGFloat = 2
    static let mediumBlur: CGFloat = 4
    static let fastBlur: CGFloat = 6
    static let celebrationBlur: CGFloat = 8
    
    static let slowGlowWidth: CGFloat = 20
    static let mediumGlowWidth: CGFloat = 30
    static let fastGlowWidth: CGFloat = 40
    static let celebrationGlowWidth: CGFloat = 50
    
    // Pulsing animation configurations
    static let slowPulseDuration: Double = 2.0
    static let mediumPulseDuration: Double = 1.5
    static let fastPulseDuration: Double = 1.0
    static let celebrationPulseDuration: Double = 0.8
}

struct AnimatedProgressRing: View {
    let progress: Double
    let steps: Int
    
    @State private var ringScale: CGFloat = 1.0 // Unused: Not actively used in animations
    @State private var ringGlowOpacity: Double = 0.3
    @State private var ringGlowWidth: CGFloat = 20
    @State private var ringBlur: CGFloat = 1
    @State private var sparkleScale: CGFloat = 1.0
    @State private var sparkleOpacity: Double = 0.0
    @State private var sparklePositions: [CGPoint] = []
    @State private var sparkleTargets: [CGPoint] = [] // Unused: Declared but never used
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowColor: Color = .white
    
    private func updateRingGlow() {
        if progress <= RingConfig.slowThreshold {
            // 0-50%: Subtle glow with slow pulse
            ringGlowOpacity = RingConfig.slowGlow
            ringBlur = RingConfig.slowBlur
            ringGlowWidth = RingConfig.slowGlowWidth
            glowColor = .white
            withAnimation(.easeInOut(duration: RingConfig.slowPulseDuration).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        } else if progress <= RingConfig.mediumThreshold {
            // 51-75%: Medium glow with faster pulse
            ringGlowOpacity = RingConfig.mediumGlow
            ringBlur = RingConfig.mediumBlur
            ringGlowWidth = RingConfig.mediumGlowWidth
            glowColor = .white.opacity(0.8)
            withAnimation(.easeInOut(duration: RingConfig.mediumPulseDuration).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        } else if progress <= RingConfig.fastThreshold {
            // 76-100%: Intense glow with rapid pulse
            ringGlowOpacity = RingConfig.fastGlow
            ringBlur = RingConfig.fastBlur
            ringGlowWidth = RingConfig.fastGlowWidth
            glowColor = .white.opacity(0.6)
            withAnimation(.easeInOut(duration: RingConfig.fastPulseDuration).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        } else {
            // 101%+: Celebration glow with quick pulse
            ringGlowOpacity = RingConfig.celebrationGlow
            ringBlur = RingConfig.celebrationBlur
            ringGlowWidth = RingConfig.celebrationGlowWidth
            glowColor = .white.opacity(0.4)
            withAnimation(.easeInOut(duration: RingConfig.celebrationPulseDuration).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
        }
    }
    
    private func updateSparklePositions() {
        let range: ClosedRange<CGFloat>
        let duration: Double
        
        if progress <= RingConfig.slowThreshold {
            // 0-50%: Sparkles stay inside the ring
            range = RingConfig.slowRange
            duration = RingConfig.slowDuration
            
            sparklePositions = (0..<RingConfig.sparkleCount).map { _ in
                let angle = Double.random(in: 0...360)
                let distance = CGFloat.random(in: 0...RingConfig.ringRadius * 0.8)
                return CGPoint(
                    x: distance * cos(CGFloat(angle) * .pi / 180),
                    y: distance * sin(CGFloat(angle) * .pi / 180)
                )
            }
            
        } else if progress <= RingConfig.mediumThreshold {
            // 51-75%: Sparkles start from center and move outward
            range = RingConfig.mediumRange
            duration = RingConfig.mediumDuration
            
            sparklePositions = (0..<RingConfig.sparkleCount).map { _ in
                let angle = Double.random(in: 0...360)
                let distance = CGFloat.random(in: RingConfig.ringRadius...RingConfig.ringRadius * 1.2)
                return CGPoint(
                    x: distance * cos(CGFloat(angle) * .pi / 180),
                    y: distance * sin(CGFloat(angle) * .pi / 180)
                )
            }
            
        } else if progress <= RingConfig.fastThreshold {
            // 76-100%: Sparkles move across top half of screen
            range = RingConfig.fastRange
            duration = RingConfig.fastDuration
            
            sparklePositions = (0..<RingConfig.sparkleCount).map { _ in
                CGPoint(
                    x: CGFloat.random(in: range),
                    y: CGFloat.random(in: -range.upperBound...0)
                )
            }
            
        } else {
            // 101%+: Calmer movement
            range = RingConfig.celebrationRange
            duration = RingConfig.celebrationDuration
            
            sparklePositions = (0..<RingConfig.sparkleCount).map { _ in
                let angle = Double.random(in: 0...360)
                let distance = CGFloat.random(in: RingConfig.ringRadius * 0.8...RingConfig.ringRadius * 1.2)
                return CGPoint(
                    x: distance * cos(CGFloat(angle) * .pi / 180),
                    y: distance * sin(CGFloat(angle) * .pi / 180)
                )
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            sparkleScale = progress > RingConfig.fastThreshold ? 1.1 : 1.0
        }
    }
    
    private func startCelebration() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            ringScale = 1.1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(.easeOut(duration: 0.5)) {
                ringScale = 1.0
            }
        }
    }
    
    private var ringView: some View {
        ZStack {
            // Background ring with enhanced glow
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            glowColor.opacity(ringGlowOpacity),
                            Color.purple.opacity(ringGlowOpacity * 0.5),
                            Color.pink.opacity(ringGlowOpacity * 0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: ringGlowWidth
                )
                .frame(width: RingConfig.ringSize, height: RingConfig.ringSize)
                .scaleEffect(ringScale * pulseScale)
                .blur(radius: ringBlur)
            
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
                .frame(width: RingConfig.ringSize, height: RingConfig.ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Sparkle effects
            ForEach(0..<RingConfig.sparkleCount, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: RingConfig.sparkleSize, height: RingConfig.sparkleSize)
                    .offset(
                        x: sparklePositions.indices.contains(index) ? sparklePositions[index].x : 0,
                        y: sparklePositions.indices.contains(index) ? sparklePositions[index].y : 0
                    )
                    .scaleEffect(sparkleScale)
                    .opacity(sparkleOpacity)
                    .animation(
                        Animation.easeInOut(duration: progress <= RingConfig.slowThreshold ? RingConfig.slowDuration :
                                            progress <= RingConfig.mediumThreshold ? RingConfig.mediumDuration :
                                            progress <= RingConfig.fastThreshold ? RingConfig.fastDuration :
                                            RingConfig.celebrationDuration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: sparkleScale
                    )
            }
        }
    }
    
    private var stepCountView: some View {
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
    
    var body: some View {
        ZStack {
            ringView
            stepCountView
        }
        .onAppear {
            withAnimation {
                sparkleScale = 1.2
                sparkleOpacity = 1.0
            }
            updateSparklePositions()
            updateRingGlow()
        }
        .onChange(of: progress) { newProgress in
            updateSparklePositions()
            updateRingGlow()
            if newProgress >= 1.0 {
                startCelebration()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        AnimatedProgressRing(progress: 0.5, steps: 5000)
    }
} 

