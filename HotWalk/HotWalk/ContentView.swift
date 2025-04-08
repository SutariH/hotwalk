import SwiftUI

struct ContentView: View {
    @StateObject private var healthManager = HealthManager()
    @StateObject private var viewModel = HotWalkViewModel()
    @State private var showingGoalEditor = false
    @State private var tempGoal: String = ""
    @State private var showHotGirlPassMessage = false
    @State private var currentMilestone: MilestoneType?
    @State private var showingMilestoneCard = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.purple.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Step count
                    Text("\(healthManager.steps)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Progress ring
                    AnimatedProgressRing(progress: viewModel.calculateProgress(steps: healthManager.steps))
                        .frame(width: 300, height: 300)
                        .padding(.top, 20)
                    
                    // Motivational message
                    Text(viewModel.currentMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Streak text
                    Text(viewModel.streakText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    // Calendar navigation button
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
                    .padding(.bottom, 30)
                }
                .padding()
                
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