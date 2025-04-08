import SwiftUI

// Add DayStatus enum at the top of the file
enum DayStatus {
    case goalMet
    case hotGirlPass
    case missed
    case today
    case none
}

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HotWalkViewModel()
    @StateObject private var healthManager = HealthManager()
    @State private var currentDate = Date()
    @State private var selectedDate: Date? = nil
    @State private var showingGoalEditor = false
    @State private var tempGoal: String = ""
    @State private var selectedDateSteps: Int = 0
    @State private var selectedDateStatus: DayStatus = .none
    
    private let calendar = Calendar.current
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // Month subheadings dictionary
    private let monthSubheadings: [Int: String] = [
        1: "✨ New Year, New Steps ✨",
        2: "💝 Love Your Daily Walks 💝",
        3: "🌸 Spring into Action 🌸",
        4: "🌺 Bloom with Every Step 🌺",
        5: "🌼 May Your Steps Flourish 🌼",
        6: "☀️ Summer Stride Season ☀️",
        7: "🌞 Sunshine Step Challenge 🌞",
        8: "🌅 August Adventure Awaits 🌅",
        9: "🍂 Fall into Fitness 🍂",
        10: "🎃 Spooky Step Season 🎃",
        11: "🍁 November Stride Guide 🍁",
        12: "❄️ December Dash Days ❄️"
    ]
    
    // Reaction messages based on status
    private func getReactionMessage(for status: DayStatus) -> String {
        switch status {
        case .goalMet:
            return "Keep the fire going 🔥"
        case .hotGirlPass:
            return "You used a Hot Girl Pass 💌. Iconic."
        case .missed:
            return "Oopsie! Even hot girls rest 😴"
        case .today:
            return "Still time to strut! 👟"
        case .none:
            return ""
        }
    }
    
    // Helper function to determine the status of a date
    private func getStatus(for date: Date) -> DayStatus {
        if calendar.isDateInToday(date) {
            return .today
        } else if isGoalMet(for: date) {
            return .goalMet
        } else if HotGirlPassManager.shared.wasPassUsed(on: date) {
            return .hotGirlPass
        } else {
            return .missed
        }
    }
    
    // Helper function to format the date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            // Updated background gradient to match main screen
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 44/255, green: 8/255, blue: 52/255), // Rich plum
                    Color.black,
                    Color.purple.opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Month navigation
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityLabel("Previous month")
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        // Seasonal subheading
                        Text(getMonthSubheading())
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .accessibilityAddTraits(.isHeader)
                        
                        // Month and year
                        Text(monthYearString(from: currentDate))
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .accessibilityAddTraits(.isHeader)
                    }
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityLabel("Next month")
                    }
                }
                .padding(.horizontal)
                
                // Streak and Pass Count Display
                HStack {
                    Text(viewModel.streakText)
                        .font(.body)
                        .foregroundColor(Color.purple.opacity(0.9))
                    
                    Text("·")
                        .font(.body)
                        .foregroundColor(Color.purple.opacity(0.9))
                    
                    Text("💌 \(HotGirlPassManager.shared.currentPassCount) Hot Girl Passes")
                        .font(.body)
                        .foregroundColor(Color.purple.opacity(0.9))
                }
                .padding(.top, 5)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(viewModel.streakText) and \(HotGirlPassManager.shared.currentPassCount) Hot Girl Passes")
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isGoalMet: isGoalMet(for: date),
                                wasPassUsed: HotGirlPassManager.shared.wasPassUsed(on: date),
                                stepCount: getStepCount(for: date)
                            )
                            .onTapGesture {
                                // Toggle selection: if tapping the same day, deselect it
                                if let selectedDate = selectedDate, calendar.isDate(selectedDate, inSameDayAs: date) {
                                    self.selectedDate = nil
                                    selectedDateStatus = .none
                                } else {
                                    self.selectedDate = date
                                    fetchSteps(for: date)
                                    selectedDateStatus = getStatus(for: date)
                                }
                            }
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityLabel("\(calendar.component(.day, from: date)), \(isGoalMet(for: date) ? "Goal met" : HotGirlPassManager.shared.wasPassUsed(on: date) ? "Pass used" : "No goal met")")
                            .accessibilityAddTraits(isGoalMet(for: date) ? [.isSelected, .isButton] : .isButton)
                        } else {
                            Color.clear
                                .aspectRatio(1, contentMode: .fill)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Day details section (only shown when a day is selected)
                if let date = selectedDate {
                    VStack(spacing: 15) {
                        // Date header
                        Text(formatDate(date))
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(.top, 5)
                            .accessibilityAddTraits(.isHeader)
                        
                        // Steps and goal
                        VStack(spacing: 10) {
                            Text("\(selectedDateSteps) steps")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Goal: \(viewModel.dailyGoal)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            ProgressView(value: Double(selectedDateSteps), total: Double(viewModel.dailyGoal))
                                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                                .frame(width: 200)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(15)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(selectedDateSteps) steps out of \(viewModel.dailyGoal) goal")
                        
                        // Status card
                        VStack(spacing: 10) {
                            if isGoalMet(for: date) {
                                Text("🔥 Goal Achieved!")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                
                                Text("You crushed your step goal this day!")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.9))
                            } else if HotGirlPassManager.shared.wasPassUsed(on: date) {
                                Text("💌 Hot Girl Pass Used")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                
                                Text("You used a pass to preserve your streak!")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.9))
                            } else {
                                Text("No Goal Met")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                
                                Text("You didn't meet your step goal this day.")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    isGoalMet(for: date) ? Color.purple.opacity(0.2) :
                                    HotGirlPassManager.shared.wasPassUsed(on: date) ? Color.pink.opacity(0.2) :
                                    Color.gray.opacity(0.2)
                                )
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            isGoalMet(for: date) ? "Goal achieved" :
                            HotGirlPassManager.shared.wasPassUsed(on: date) ? "Hot Girl Pass used" :
                            "No goal met"
                        )
                        
                        // Affirmation message with improved styling
                        if selectedDateStatus != .none {
                            Text(getReactionMessage(for: selectedDateStatus))
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 0)
                                .padding(.top, 5)
                                .accessibilityLabel(getReactionMessage(for: selectedDateStatus))
                        }
                        
                        // Redesigned action buttons
                        HStack(spacing: 12) {
                            // Slayed It button
                            HStack(spacing: 6) {
                                Text("🔥")
                                    .font(.system(size: 16))
                                
                                Text("Slayed It")
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.purple.opacity(0.3))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .accessibilityLabel("Slayed It badge")
                            
                            // Hot Girl Pass button
                            HStack(spacing: 6) {
                                Text("💌")
                                    .font(.system(size: 16))
                                
                                Text("Hot Girl Pass")
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.pink.opacity(0.3))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .accessibilityLabel("Hot Girl Pass badge")
                            
                            // Oops button
                            HStack(spacing: 6) {
                                Text("😴")
                                    .font(.system(size: 16))
                                
                                Text("Oops")
                                    .font(.subheadline.weight(.medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white.opacity(0.8))
                            .clipShape(Capsule())
                            .accessibilityLabel("Oops badge")
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.3), value: selectedDate)
                }
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: EmptyView(),
            trailing: Button(action: {
                tempGoal = String(viewModel.dailyGoal)
                showingGoalEditor = true
            }) {
                Image(systemName: "gear")
                    .foregroundColor(.white)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Settings")
            }
        )
        .sheet(isPresented: $showingGoalEditor) {
            GoalEditorView(
                goal: $tempGoal,
                onSave: { newGoal in
                    if let goal = Int(newGoal) {
                        viewModel.dailyGoal = goal
                        showingGoalEditor = false
                    }
                },
                onCancel: { showingGoalEditor = false }
            )
        }
        .onAppear {
            fetchSteps(for: currentDate)
        }
    }
    
    private func getMonthSubheading() -> String {
        let month = calendar.component(.month, from: currentDate)
        return monthSubheadings[month] ?? ""
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        let interval = calendar.dateInterval(of: .month, for: currentDate)!
        let firstDay = interval.start
        
        // Get the weekday of the first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        
        // Get the number of days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentDate)!.count
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        // Pad the end of the array to make complete weeks
        let remainingCells = 42 - days.count // 6 rows * 7 days = 42
        days.append(contentsOf: Array(repeating: nil, count: remainingCells))
        
        return days
    }
    
    private func isGoalMet(for date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        return UserDefaults.standard.bool(forKey: "goal_completed_\(dateString)")
    }
    
    private func getStepCount(for date: Date) -> Int {
        // In a real app, this would fetch from HealthKit
        // For now, we'll use a placeholder value
        return 0
    }
    
    private func fetchSteps(for date: Date) {
        // Create date boundaries for the selected day (00:00 to 23:59:59)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)!
        
        // In a real app, this would fetch from HealthKit with the correct date boundaries
        // For now, we'll use a placeholder value that's consistent for the same date
        // This ensures the same date always returns the same step count
        let dateString = dateFormatter.string(from: date)
        let hash = dateString.hashValue
        selectedDateSteps = (hash % (viewModel.dailyGoal * 2)) + Int.random(in: 0...viewModel.dailyGoal)
        
        // In a real implementation, you would use HealthKit like this:
        /*
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    self.selectedDateSteps = 0
                }
                return
            }
            
            DispatchQueue.main.async {
                self.selectedDateSteps = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        
        healthManager.healthStore.execute(query)
        */
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

struct DayCell: View {
    let date: Date
    let isGoalMet: Bool
    let wasPassUsed: Bool
    let stepCount: Int
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundColor)
                .overlay(
                    Circle()
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
                .shadow(color: shadowColor, radius: shadowRadius)
            
            // Day number
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: textWeight))
                .foregroundColor(textColor)
            
            // Status icon
            if isGoalMet {
                Text("🔥")
                    .font(.system(size: 14))
                    .offset(x: 8, y: -8)
                    .accessibilityHidden(true)
            } else if wasPassUsed {
                Text("💌")
                    .font(.system(size: 14))
                    .offset(x: 8, y: -8)
                    .accessibilityHidden(true)
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .frame(maxWidth: .infinity)
    }
    
    private var backgroundColor: Color {
        if isGoalMet {
            return Color.purple.opacity(0.3)
        } else if wasPassUsed {
            return Color.pink.opacity(0.3)
        }
        return Color.clear
    }
    
    private var borderColor: Color {
        if isGoalMet {
            return Color.purple
        } else if wasPassUsed {
            return Color.pink
        }
        return Color.gray.opacity(0.3)
    }
    
    private var borderWidth: CGFloat {
        if isGoalMet || wasPassUsed {
            return 2
        }
        return 1
    }
    
    private var textColor: Color {
        if isGoalMet {
            return Color.white
        } else if wasPassUsed {
            return Color.white
        }
        return Color.white
    }
    
    private var textWeight: Font.Weight {
        if isGoalMet || wasPassUsed {
            return .bold
        }
        return .regular
    }
    
    private var shadowColor: Color {
        if isGoalMet {
            return Color.purple.opacity(0.3)
        } else if wasPassUsed {
            return Color.pink.opacity(0.3)
        }
        return Color.clear
    }
    
    private var shadowRadius: CGFloat {
        if isGoalMet || wasPassUsed {
            return 3
        }
        return 0
    }
}

struct GoalEditorView: View {
    @Binding var goal: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set Daily Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                TextField("Steps", text: $goal)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                    .foregroundColor(.white)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Cancel goal editing")
                    
                    Button("Save") {
                        onSave(goal)
                    }
                    .foregroundColor(.white)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Save new goal")
                }
            }
            .padding()
            .background(Color.purple.opacity(0.8))
            .cornerRadius(15)
        }
    }
}

#Preview {
    NavigationView {
        CalendarView()
    }
} 
