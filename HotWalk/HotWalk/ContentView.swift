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
                LinearGradient(gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.3)]),
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Step Count
                    VStack {
                        Text("\(healthManager.steps)")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(.purple)
                        
                        Text("steps today")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        // Streak Display
                        Text(viewModel.streakText)
                            .font(.title3)
                            .foregroundColor(.purple)
                            .padding(.top, 5)
                    }
                    .padding(.top, 50)
                    
                    // Progress Bar
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 20)
                            .opacity(0.3)
                            .foregroundColor(.gray)
                        
                        Circle()
                            .trim(from: 0.0, to: viewModel.calculateProgress(steps: healthManager.steps))
                            .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                            .foregroundColor(.purple)
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear, value: healthManager.steps)
                        
                        VStack {
                            Text("Goal: \(viewModel.dailyGoal)")
                                .font(.headline)
                            Button("Edit Goal") {
                                tempGoal = String(viewModel.dailyGoal)
                                showingGoalEditor = true
                            }
                            .foregroundColor(.purple)
                        }
                    }
                    .frame(width: 250, height: 250)
                    
                    // Hot Girl Pass Message
                    if !viewModel.hotGirlPassMessage.isEmpty {
                        Text(viewModel.hotGirlPassMessage)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.purple)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(radius: 5)
                            )
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .onAppear {
                                showHotGirlPassMessage = true
                                // Clear the message after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        showHotGirlPassMessage = false
                                        viewModel.hotGirlPassMessage = ""
                                    }
                                }
                            }
                    }
                    
                    // Motivational Message
                    VStack(spacing: 10) {
                        Text(viewModel.currentMessage)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.purple)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(radius: 5)
                            )
                            .padding(.horizontal)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: viewModel.currentMessage)
                    
                    // Calendar Navigation Button
                    NavigationLink(destination: CalendarView()) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.title2)
                            Text("View Streak Calendar")
                                .font(.headline)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.purple.opacity(0.2))
                                .shadow(radius: 3)
                        )
                        .foregroundColor(.purple)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding()
                
                // Milestone Card Overlay
                if showingMilestoneCard, let milestone = currentMilestone {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    MilestoneCardView(
                        milestone: milestone,
                        onDismiss: {
                            withAnimation {
                                showingMilestoneCard = false
                                currentMilestone = nil
                            }
                        },
                        onShare: {
                            // Share functionality will be implemented later
                        }
                    )
                    .transition(.scale)
                }
            }
            .navigationTitle("Hot Walk")
            .sheet(isPresented: $showingGoalEditor) {
                NavigationView {
                    Form {
                        Section(header: Text("Set Daily Step Goal")) {
                            TextField("Steps", text: $tempGoal)
                                .keyboardType(.numberPad)
                        }
                    }
                    .navigationTitle("Edit Goal")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingGoalEditor = false
                        },
                        trailing: Button("Save") {
                            if let newGoal = Int(tempGoal) {
                                viewModel.dailyGoal = newGoal
                            }
                            showingGoalEditor = false
                        }
                    )
                }
            }
            .onAppear {
                // Start a timer to update steps every minute
                Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                    healthManager.fetchTodaySteps()
                    checkForMilestones()
                }
            }
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
}

#Preview {
    ContentView()
} 