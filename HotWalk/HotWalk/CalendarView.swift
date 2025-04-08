import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HotWalkViewModel()
    @StateObject private var healthManager = HealthManager()
    @State private var currentDate = Date()
    @State private var selectedDate: Date? = nil
    @State private var showingDateInfo = false
    @State private var showingGoalEditor = false
    @State private var tempGoal: String = ""
    @State private var selectedDateSteps: Int = 0
    
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
                                selectedDate = date
                                fetchSteps(for: date)
                                showingDateInfo = true
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
                
                // Selected date details
                if let date = selectedDate {
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
                }
                
                // Legend
                VStack(spacing: 15) {
                    Text("Calendar Legend")
                        .font(.headline)
                        .foregroundColor(.purple)
                        .accessibilityAddTraits(.isHeader)
                    
                    HStack(spacing: 20) {
                        // Goal met with flame
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .overlay(
                                    Text("🔥")
                                        .font(.system(size: 10))
                                )
                                .frame(width: 24, height: 24)
                            Text("Goal Met")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.purple)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Goal met, indicated by a flame icon")
                        
                        // Hot Girl Pass used
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.pink.opacity(0.3))
                                .overlay(
                                    Text("💌")
                                        .font(.system(size: 10))
                                )
                                .frame(width: 24, height: 24)
                            Text("Pass Used")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.purple)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Hot Girl Pass used, indicated by an envelope icon")
                        
                        // Missed day
                        HStack(spacing: 8) {
                            Circle()
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(width: 24, height: 24)
                            Text("Missed")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.purple)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Missed day, indicated by an empty circle")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.15))
                        .shadow(radius: 3)
                )
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Calendar Legend: Goal met, Pass used, and Missed day indicators")
                
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
        .sheet(isPresented: $showingDateInfo) {
            if let date = selectedDate {
                DateInfoView(date: date, isGoalMet: isGoalMet(for: date), wasPassUsed: HotGirlPassManager.shared.wasPassUsed(on: date))
            }
        }
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
        // In a real app, this would fetch from HealthKit
        // For now, we'll use a placeholder value
        selectedDateSteps = Int.random(in: 0...viewModel.dailyGoal * 2)
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

struct DateInfoView: View {
    let date: Date
    let isGoalMet: Bool
    let wasPassUsed: Bool
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(dateFormatter.string(from: date))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                if isGoalMet {
                    VStack(spacing: 10) {
                        Text("🔥 Goal Achieved!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("You crushed your step goal this day!")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.purple.opacity(0.2))
                    )
                } else if wasPassUsed {
                    VStack(spacing: 10) {
                        Text("💌 Hot Girl Pass Used")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("You used a pass to preserve your streak!")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.pink.opacity(0.2))
                    )
                } else {
                    VStack(spacing: 10) {
                        Text("No Goal Met")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("You didn't meet your step goal this day.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.2))
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Day Details")
            .navigationBarItems(trailing: Button("Slay") {
                // Dismiss the sheet
            }
            .foregroundColor(.white)
            .font(.body.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Close Calendar")
            )
        }
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
