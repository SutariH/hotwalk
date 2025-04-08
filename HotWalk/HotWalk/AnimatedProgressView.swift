import SwiftUI

// MARK: - Progress Animation States
enum ProgressAnimationState: Equatable {
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
    
    // Implement Equatable
    static func == (lhs: ProgressAnimationState, rhs: ProgressAnimationState) -> Bool {
        switch (lhs, rhs) {
        case (.early, .early):
            return true
        case (.nearing, .nearing):
            return true
        case (.completed, .completed):
            return true
        default:
            return false
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
    let emoji: String
    let orbitRadius: CGFloat
    let orbitSpeed: Double
    let pulseEffect: Bool
    let isOutsideRing: Bool
    let orbitDirection: Double // 1.0 for clockwise, -1.0 for counterclockwise
    
    @State private var currentPosition: CGPoint
    @State private var currentScale: CGFloat = 1.0
    @State private var currentOpacity: Double
    @State private var orbitAngle: Double = 0
    
    init(position: CGPoint, size: CGFloat, opacity: Double, rotation: Double, 
         animationSpeed: Double, emoji: String = "✨", 
         orbitRadius: CGFloat = 0, orbitSpeed: Double = 0, pulseEffect: Bool = false,
         isOutsideRing: Bool = false, orbitDirection: Double = 1.0) {
        self.position = position
        self.size = size
        self.opacity = opacity
        self.rotation = rotation
        self.animationSpeed = animationSpeed
        self.emoji = emoji
        self.orbitRadius = orbitRadius
        self.orbitSpeed = orbitSpeed
        self.pulseEffect = pulseEffect
        self.isOutsideRing = isOutsideRing
        self.orbitDirection = orbitDirection
        
        // Initialize state variables
        _currentPosition = State(initialValue: position)
        _currentOpacity = State(initialValue: opacity)
        _orbitAngle = State(initialValue: Double.random(in: 0...360))
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Text(emoji)
                .font(.system(size: size * currentScale))
                .foregroundColor(.white)
                .opacity(currentOpacity)
                .position(currentPosition)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    startAnimations()
                }
                .onChange(of: timeline.date) { _ in
                    updatePosition()
                }
        }
    }
    
    private func updatePosition() {
        // Update orbit angle based on time
        orbitAngle += orbitSpeed * 0.1 * orbitDirection
        
        // Calculate new position using polar to Cartesian conversion
        let radians = orbitAngle * .pi / 180
        let x = position.x + cos(radians) * orbitRadius
        let y = position.y + sin(radians) * orbitRadius
        currentPosition = CGPoint(x: x, y: y)
    }
    
    private func startAnimations() {
        // Pulse animation if needed
        if pulseEffect {
            withAnimation(
                .easeInOut(duration: animationSpeed * 0.5)
                .repeatForever(autoreverses: true)
            ) {
                currentScale = 1.2
                currentOpacity = min(opacity * 1.5, 1.0)
            }
        }
    }
}

// MARK: - Animated Progress Ring
struct AnimatedProgressRing: View {
    let progress: Double
    @State private var sparkles: [(id: UUID, position: CGPoint, size: CGFloat, opacity: Double, rotation: Double, emoji: String, orbitRadius: CGFloat, orbitSpeed: Double, pulseEffect: Bool, isOutsideRing: Bool, orbitDirection: Double)] = []
    @State private var showCelebration = false
    @State private var hasCelebratedToday = false
    @State private var showGlowEffect = false
    @State private var glowOpacity: Double = 0.0
    @State private var celebrationTimer: Timer? = nil
    
    private let userDefaults = UserDefaults.standard
    private let celebrationKey = "lastCelebrationDate"
    
    var body: some View {
        ZStack {
            // Glow effect for completed state
            if showGlowEffect {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink.opacity(0.6), .purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 30, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .blur(radius: 10)
                    .opacity(glowOpacity)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowOpacity)
            }
            
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
                    animationSpeed: getAnimationSpeed(),
                    emoji: sparkle.emoji,
                    orbitRadius: sparkle.orbitRadius,
                    orbitSpeed: sparkle.orbitSpeed,
                    pulseEffect: sparkle.pulseEffect,
                    isOutsideRing: sparkle.isOutsideRing,
                    orbitDirection: sparkle.orbitDirection
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
                    // After celebration, show the simmering state
                    if progress >= 1.0 {
                        showGlowEffect = true
                        glowOpacity = 0.7
                    }
                }
            }
        }
    }
    
    private func getAnimationSpeed() -> Double {
        switch ProgressAnimationState.fromProgress(progress) {
        case .early:
            return 3.0 // Slow, lazy sparkles
        case .nearing:
            return 2.0 // Medium speed
        case .completed:
            return 1.5 // Slower after celebration
        }
    }
    
    private func updateAnimationState(for progress: Double) {
        let state = ProgressAnimationState.fromProgress(progress)
        let previousState = sparkles.isEmpty ? nil : ProgressAnimationState.fromProgress(progress - 0.01)
        
        // Check if we're crossing the 100% threshold
        let crossingThreshold = previousState != nil && 
            !isCompletedState(previousState!) && 
            isCompletedState(state)
        
        // Clear existing sparkles
        sparkles.removeAll()
        
        switch state {
        case .early:
            // Few, slow sparkles - lazy mode
            addSparkles(
                count: Int.random(in: 2...3), 
                speed: 1.5, 
                orbitRadius: 80, 
                orbitSpeed: 0.3, 
                pulseEffect: false,
                isOutsideRing: false,
                emojis: ["✨"]
            )
            
        case .nearing:
            // More, faster sparkles with orbit and pulse
            addSparkles(
                count: Int.random(in: 3...5), 
                speed: 1.0, 
                orbitRadius: 100, 
                orbitSpeed: 8.8,
                pulseEffect: true,
                isOutsideRing: true,
                emojis: ["✨", "💫"]
            )
            
        case .completed:
            // Many, fast sparkles with enhanced effects
            addSparkles(
                count: Int.random(in: 3...4), 
                speed: 2.8,
                orbitRadius: 120,
                orbitSpeed: 0.4, 
                pulseEffect: true,
                isOutsideRing: true,
                emojis: ["✨", "💫", "🌟"]
            )
            
            // Show glow effect for completed state
            showGlowEffect = true
            glowOpacity = 0.7
            
            // Check if we should show celebration
            if crossingThreshold && !hasCelebratedToday {
                checkAndShowCelebration()
            }
        }
    }
    
    // Helper function to check if a state is completed
    private func isCompletedState(_ state: ProgressAnimationState) -> Bool {
        switch state {
        case .completed:
            return true
        default:
            return false
        }
    }
    
    private func addSparkles(count: Int, speed: Double, orbitRadius: CGFloat, orbitSpeed: Double, pulseEffect: Bool, isOutsideRing: Bool, emojis: [String]) {
        let centerX: CGFloat = 100
        let centerY: CGFloat = 100
        let ringRadius: CGFloat = 100
        
        for _ in 0..<count {
            // For outside ring sparkles, position them further out
            let radius: CGFloat = isOutsideRing ? 
                ringRadius + CGFloat.random(in: 20...40) : 
                CGFloat.random(in: 30...ringRadius - 10)
            
            let angle = Double.random(in: 0...360)
            let x = centerX + cos(angle) * radius
            let y = centerY + sin(angle) * radius
            
            // Randomly choose orbit direction (clockwise or counterclockwise)
            let orbitDirection = Double.random(in: 0...1) > 0.5 ? 1.0 : -1.0
            
            sparkles.append((
                id: UUID(),
                position: CGPoint(x: x, y: y),
                size: CGFloat.random(in: 10...20),
                opacity: Double.random(in: 0.3...0.7),
                rotation: Double.random(in: 0...360),
                emoji: emojis.randomElement() ?? "✨",
                orbitRadius: orbitRadius,
                orbitSpeed: orbitSpeed,
                pulseEffect: pulseEffect,
                isOutsideRing: isOutsideRing,
                orbitDirection: orbitDirection
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
        
        // Set a timer to automatically dismiss the celebration after 5 seconds
        celebrationTimer?.invalidate()
        celebrationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            showCelebration = false
        }
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
