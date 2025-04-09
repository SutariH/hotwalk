import SwiftUI

struct ContentView: View {
    @StateObject private var healthManager = HealthManager()
    @StateObject private var viewModel = HotWalkViewModel()
    @State private var showingGoalEditor = false
    @State private var tempGoal: String = ""
    @State private var showHotGirlPassMessage = false
    @State private var currentMilestone: MilestoneType?
    @State private var showingMilestoneCard = false
    @State private var isShowingAffirmation = false
    @State private var rotationAngle: Double = 0
    @State private var currentAffirmation = ""
    @State private var flipped = false
    
    // Share CTA messages
    private let shareCTAMessages = [
        "Hot girl reset complete 🔁 Show it off!",
        "Twerked those toes today? Share the glow ✨",
        "Wednesday? More like Win-slay-day. Brag now 💅",
        "Thirsty for attention? Let your steps speak 💧",
        "Hot girl walk ➡️ Hot girl flex. Tap to share 📸",
        "Steps > drama. Tell the world 🌍",
        "Sundays are for sparkle recaps ✨ Drop yours!",
        "Serving walk-core excellence 🏆 Let 'em know",
        "You slayed the sidewalk—now slay the feed 🔥",
        "Got that step drip 💧 Share it loud!",
        "Main character energy detected 📢 Show it!",
        "Too cute not to post. Tap that share 💖"
    ]
    
    private var currentShareMessage: String {
        let day = Calendar.current.component(.day, from: Date())
        return shareCTAMessages[day % shareCTAMessages.count]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 44/255, green: 8/255, blue: 52/255),
                        Color.purple.opacity(0.3),
                        Color(hue: 0.83, saturation: 0.3, brightness: 0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Title
                        Text("Hot Girl Steps")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                            .padding(.bottom, 10)
                        
                        // Step Ring with Flip Animation
                        ZStack {
                            // Front of card (Step Ring with step count)
                            AnimatedProgressRing(progress: viewModel.calculateProgress(steps: healthManager.steps), steps: healthManager.steps)
                                .rotation3DEffect(
                                    Angle(degrees: rotationAngle),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                                .opacity(isShowingAffirmation ? 0 : 1)
                            
                            // Back of card (Affirmation)
                            if isShowingAffirmation {
                                AffirmationCardView(affirmation: currentAffirmation)
                                    .rotation3DEffect(
                                        Angle(degrees: rotationAngle - 180),
                                        axis: (x: 0, y: 1, z: 0)
                                    )
                            }
                        }
                        .frame(width: 300, height: 300)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                rotationAngle += 180
                                if !isShowingAffirmation {
                                    currentAffirmation = AffirmationManager.shared.getNextAffirmation()
                                }
                                isShowingAffirmation.toggle()
                            }
                        }
                        
                        // Goal percentage display (always visible below the ring)
                        Text("\(Int((Double(healthManager.steps) / Double(viewModel.dailyGoal)) * 100))% of goal")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(0.9)
                            .padding(.top, 8)
                        
                        // Motivational message
                        Text(viewModel.currentMessage)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.8)
                            .accessibilityLabel("Motivational message: \(viewModel.currentMessage)")
                        
                        // Streak text
                        Text(viewModel.streakText)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        // Share section
                        VStack(spacing: 12) {
                            // View History button
                            NavigationLink(destination: CalendarView()) {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("View History")
                                }
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.purple.opacity(0.3))
                                .cornerRadius(15)
                            }
                            
                            // Share CTA message
                            Text(currentShareMessage)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            // Share button
                            Button(action: {
                                shareMilestone()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Your Steps")
                                }
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.purple.opacity(0.8),
                                            Color.purple.opacity(0.6)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityLabel("Share your step count")
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .padding()
                }
                
                // Goal editor overlay
                if showingGoalEditor {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showingGoalEditor = false
                        }
                    
                    VStack(spacing: 20) {
                        Text("Set Daily Goal")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        TextField("Steps", text: $tempGoal)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                        
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                showingGoalEditor = false
                            }
                            .foregroundColor(.white)
                            
                            Button("Save") {
                                if let newGoal = Int(tempGoal) {
                                    viewModel.dailyGoal = newGoal
                                    showingGoalEditor = false
                                }
                            }
                            .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.8))
                    .cornerRadius(15)
                }
                
                // Milestone card overlay
                if showingMilestoneCard {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showingMilestoneCard = false
                        }
                    
                    MilestoneCardView(
                        milestone: currentMilestone ?? .threeDayStreak,
                        onDismiss: {
                            showingMilestoneCard = false
                        },
                        onShare: {
                            shareMilestone()
                        }
                    )
                }
            }
            .navigationBarItems(trailing: Button(action: {
                tempGoal = String(viewModel.dailyGoal)
                showingGoalEditor = true
            }) {
                Image(systemName: "gear")
                    .foregroundColor(.white)
            })
        }
        .onAppear {
            // Make navigation bar transparent
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()
            navBarAppearance.backgroundColor = .clear

            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
            UINavigationBar.appearance().compactAppearance = navBarAppearance
            
            // Initial step fetch
            healthManager.fetchTodaySteps()
            
            // Set up timer to update steps every minute
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                healthManager.fetchTodaySteps()
                checkForMilestones()
            }
        }
        .onChange(of: healthManager.steps) { newSteps in
            viewModel.steps = newSteps
        }
    }
    
    private func checkForMilestones() {
        if let milestone = MilestoneManager.shared.checkForMilestones(
            streak: viewModel.getCurrentStreak(),
            progress: viewModel.calculateProgress(steps: healthManager.steps)
        ) {
            currentMilestone = milestone
            withAnimation {
                showingMilestoneCard = true
            }
        }
    }
    
    private func shareMilestone() {
        // Implementation of shareMilestone function
    }
}

#Preview {
    ContentView()
}

// Add ScaleButtonStyle at the bottom of the file
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
} 