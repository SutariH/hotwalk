import SwiftUI

// Configuration struct for animation parameters
private struct RingConfig {
    static let ringSize: CGFloat = 250
}

struct AnimatedProgressRing: View {
    let progress: Double
    let steps: Int
    
    @State private var ringScale: CGFloat = 1.0
    @State private var ringGlowOpacity: Double = 0.3
    
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
                .frame(width: RingConfig.ringSize, height: RingConfig.ringSize)
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
                .frame(width: RingConfig.ringSize, height: RingConfig.ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
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
        .onChange(of: progress) { newProgress in
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

