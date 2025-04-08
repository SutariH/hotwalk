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
    let animationSpeed: Double
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundColor(.white)
            .opacity(opacity)
            .position(position)
            .rotationEffect(.degrees(rotation))
            .animation(
                .easeInOut(duration: animationSpeed)
                .repeatForever(autoreverses: true),
                value: rotation
            )
    }
}

// MARK: - Animated Progress Ring
struct AnimatedProgressRing: View {
    let progress: Double
    @State private var sparkles: [(id: UUID, position: CGPoint, size: CGFloat, opacity: Double, rotation: Double)] = []
    @State private var showCelebration = false
    @State private var hasCelebratedToday = false
    
    private let userDefaults = UserDefaults.standard
    private let celebrationKey = "lastCelebrationDate"
    
    var body: some View {
        ZStack {
            // Progress ring background
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 20)
                .frame(width: 200, height: 200)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.pink, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Sparkles
            ForEach(sparkles, id: \.id) { sparkle in
                SparkleView(
                    position: sparkle.position,
                    size: sparkle.size,
                    opacity: sparkle.opacity,
                    rotation: sparkle.rotation,
                    animationSpeed: getAnimationSpeed()
                )
            }
        }
        .onChange(of: progress) { newProgress in
            updateAnimationState(for: newProgress)
        }
        .overlay {
            if showCelebration {
                CelebrationView {
                    showCelebration = false
                }
            }
        }
    }
    
    private func getAnimationSpeed() -> Double {
        switch ProgressAnimationState.fromProgress(progress) {
        case .early:
            return 2.0
        case .nearing:
            return 1.0
        case .completed:
            return 0.5
        }
    }
    
    private func updateAnimationState(for progress: Double) {
        let state = ProgressAnimationState.fromProgress(progress)
        
        // Clear existing sparkles
        sparkles.removeAll()
        
        switch state {
        case .early:
            // Few, slow sparkles
            addSparkles(count: 3, speed: 2.0)
            
        case .nearing:
            // More, faster sparkles
            addSparkles(count: 6, speed: 1.0)
            
        case .completed:
            // Many, fast sparkles
            addSparkles(count: 9, speed: 0.5)
            
            // Check if we should show celebration
            if !hasCelebratedToday {
                checkAndShowCelebration()
            }
        }
    }
    
    private func addSparkles(count: Int, speed: Double) {
        for _ in 0..<count {
            let angle = Double.random(in: 0...360)
            let radius: CGFloat = 100
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            
            sparkles.append((
                id: UUID(),
                position: CGPoint(x: x + 100, y: y + 100),
                size: CGFloat.random(in: 10...20),
                opacity: Double.random(in: 0.3...0.7),
                rotation: Double.random(in: 0...360)
            ))
        }
    }
    
    private func checkAndShowCelebration() {
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        
        if let lastCelebration = userDefaults.string(forKey: celebrationKey),
           lastCelebration == todayString {
            hasCelebratedToday = true
            return
        }
        
        // Show celebration and update last celebration date
        showCelebration = true
        userDefaults.set(todayString, forKey: celebrationKey)
        hasCelebratedToday = true
    }
}

// Preview provider
struct AnimatedProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                AnimatedProgressRing(progress: 0.3)
                AnimatedProgressRing(progress: 0.8)
                AnimatedProgressRing(progress: 1.0)
            }
        }
    }
} 