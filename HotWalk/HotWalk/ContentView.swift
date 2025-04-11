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
    
    // Share CTA messages - moved to static property
    private static let shareCTAMessages = [
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
    
    // Computed property for share message
    private var currentShareMessage: String {
        let day = Calendar.current.component(.day, from: Date())
        return Self.shareCTAMessages[day % Self.shareCTAMessages.count]
    }
    
    // Cached views
    private var progressRingView: some View {
        AnimatedProgressRing(
            progress: viewModel.calculateProgress(steps: healthManager.steps),
            steps: healthManager.steps
        )
        .rotation3DEffect(
            Angle(degrees: rotationAngle),
            axis: (x: 0, y: 1, z: 0)
        )
        .opacity(isShowingAffirmation ? 0 : 1)
    }
    
    private var affirmationView: some View {
        AffirmationCardView(affirmation: currentAffirmation)
            .rotation3DEffect(
                Angle(degrees: rotationAngle - 180),
                axis: (x: 0, y: 1, z: 0)
            )
    }
    
    private var shareSection: some View {
        VStack(spacing: 24) {
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
            .padding(.bottom, 8)
            
            Text(currentShareMessage)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            Button(action: shareMilestone) {
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
    
    var body: some View {
        NavigationView {
        ZStack {
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
                    VStack(spacing: 40) {
                        Image("HotGirlStepsLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                            .padding(.top, 30)
                            .padding(.bottom, 10)
                        
                        ZStack {
                            progressRingView
                            if isShowingAffirmation {
                                affirmationView
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
                        
                        VStack(spacing: 16) {
                            Text("\(Int((Double(healthManager.steps) / Double(viewModel.dailyGoal)) * 100))% of goal")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .opacity(0.9)
                            
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
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                                .minimumScaleFactor(0.8)
                                .accessibilityLabel("Motivational message: \(viewModel.currentMessage)")
                            
                            Text(viewModel.streakText)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        shareSection
                            .padding(.top, 40)
                    }
                    .padding(.horizontal)
                }
                
                .sheet(isPresented: $showingGoalEditor) {
                    GoalEditorView(viewModel: viewModel)
                }
                
                if showingMilestoneCard {
                    milestoneCardOverlay
                }
            }
            .navigationBarItems(trailing: Button(action: {
                showingGoalEditor = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.white)
            })
        }
        .onAppear {
            setupNavigationBar()
            healthManager.fetchTodaySteps()
            setupStepUpdateTimer()
        }
        .onChange(of: healthManager.steps) { newSteps in
            viewModel.steps = newSteps
        }
    }
    
    private var milestoneCardOverlay: some View {
        Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                showingMilestoneCard = false
            }
            .overlay(
                MilestoneCardView(
                    milestone: currentMilestone ?? .threeDayStreak,
                    onClose: {
                        withAnimation {
                            showingMilestoneCard = false
                        }
                    },
                    onShare: {
                        shareMilestone()
                    }
                )
            )
    }
    
    private func setupNavigationBar() { // Unused: Not called anywhere in the app
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .clear

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
    
    private func setupStepUpdateTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            healthManager.fetchTodaySteps()
            checkForMilestones()
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
        // Create the share card view
        let shareCard = ShareCardView(
            steps: healthManager.steps,
            goalPercentage: Int((Double(healthManager.steps) / Double(viewModel.dailyGoal)) * 100),
            message: viewModel.currentMessage,
            dailyGoal: viewModel.dailyGoal
        )
        
        // Convert the view to an image
        let image: UIImage?
        
        if #available(iOS 16.0, *) {
            // Use ImageRenderer for iOS 16+
            let renderer = ImageRenderer(content: shareCard)
            renderer.scale = UIScreen.main.scale
            image = renderer.uiImage
        } else if #available(iOS 10.0, *) {
            // Use UIGraphicsImageRenderer for iOS 10-15
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 350, height: 500))
            image = renderer.image { context in
                let hostingController = UIHostingController(rootView: shareCard)
                hostingController.view.frame = CGRect(x: 0, y: 0, width: 350, height: 500)
                hostingController.view.backgroundColor = .clear
                hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
            }
        } else {
            // Fallback for iOS 9 and earlier
            let size = CGSize(width: 350, height: 500)
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            let hostingController = UIHostingController(rootView: shareCard)
            hostingController.view.frame = CGRect(x: 0, y: 0, width: 350, height: 500)
            hostingController.view.backgroundColor = .clear
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        
        // Share the image
        if let image = image {
            // Create activity items
            let activityItems: [Any] = [
                image,
                "Check out my Hot Girl Steps! 🚶‍♀️✨ #HotGirlWalk"
            ]
            
            // Create activity view controller
            let activityVC = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
            
            // Exclude some activity types that might cause issues
            activityVC.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList,
                .openInIBooks
            ]
            
            // Configure for iPad
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            // Present the share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
}

#Preview {
    ContentView()
} 

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
} 
