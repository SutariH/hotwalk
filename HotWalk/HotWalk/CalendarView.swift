import SwiftUI
import HealthKit

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
    @State private var todaySteps: Int = 0
    @State private var isTransitioning: Bool = false
    @State private var stepCountCache: [Date: Int] = [:]
    @State private var isFetchingData: Bool = false
    
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
            return "Slaying steps like it's your job 💃"
        case .hotGirlPass:
            return "Hot girl pass: The ultimate power move 💅"
        case .missed:
            return "Even icons need their beauty sleep 😴"
        case .today:
            return todaySteps >= viewModel.dailyGoal ? 
                "Slaying steps like it's your job 💃" : 
                "Time to turn up the heat! 🔥"
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
                VStack(spacing: 24) {
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
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isTransitioning = true
                                        
                                        if let selectedDate = selectedDate, calendar.isDate(selectedDate, inSameDayAs: date) {
                                            self.selectedDate = nil
                                            selectedDateStatus = .none
                                        } else {
                                            self.selectedDate = date
                                            fetchDailySteps(for: date) { steps in
                                                selectedDateSteps = Int(steps)
                                                selectedDateStatus = getStatus(for: date)
                                            }
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isTransitioning = false
                                        }
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
                    
                    // Streak and Passes Cards
                    HStack(spacing: 12) {
                        // Streak Card
                        VStack(spacing: 4) {
                            Text("🔥 Streak")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(viewModel.streakText)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 2)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Current streak: \(viewModel.streakText)")
                        
                        // Passes Card
                        VStack(spacing: 4) {
                            Text("💌 Hot Girl Passes")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(HotGirlPassManager.shared.currentPassCount) left")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.pink.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.pink.opacity(0.3), radius: 5, x: 0, y: 2)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(HotGirlPassManager.shared.currentPassCount) Hot Girl Passes remaining")
                    }
                    .padding(.horizontal)
                    
                    // Day details section
                    VStack(spacing: 15) {
                        // Date header
                        Text(formatDate(selectedDate ?? Date()))
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(.top, 5)
                            .accessibilityAddTraits(.isHeader)
                        
                        // Steps and goal
                        VStack(spacing: 10) {
                            Text("\(selectedDate == nil ? todaySteps : selectedDateSteps) steps")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Goal: \(viewModel.dailyGoal)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            ProgressView(
                                value: Double(selectedDate == nil ? todaySteps : selectedDateSteps), 
                                total: Double(viewModel.dailyGoal)
                            )
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                            .frame(width: 200)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(15)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(selectedDate == nil ? todaySteps : selectedDateSteps) steps out of \(viewModel.dailyGoal) goal")
                        
                        // Status card
                        VStack(spacing: 10) {
                            if let date = selectedDate {
                                // Selected date status
                                if selectedDateSteps >= viewModel.dailyGoal {
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
                                    Text("Goal Not Met")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("You didn't meet your step goal this day.")
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            } else {
                                // Today's status
                                if todaySteps >= viewModel.dailyGoal {
                                    Text("🔥 Goal Achieved!")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("You crushed your step goal today!")
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.white.opacity(0.9))
                                } else {
                                    Text("Goal Not Met")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("Still time to reach your step goal!")
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    selectedDate == nil ? 
                                        (todaySteps >= viewModel.dailyGoal ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2)) :
                                        (selectedDateSteps >= viewModel.dailyGoal ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                                )
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            selectedDate == nil ? 
                                (todaySteps >= viewModel.dailyGoal ? "Goal achieved" : "Goal not met yet") :
                                (selectedDateSteps >= viewModel.dailyGoal ? "Goal achieved" : "Goal not met")
                        )
                        
                        // Affirmation message
                        Text(getReactionMessage(for: selectedDate == nil ? .today : selectedDateStatus))
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
                            .accessibilityLabel(getReactionMessage(for: selectedDate == nil ? .today : selectedDateStatus))
                    }
                    .padding(.horizontal)
                    .opacity(isTransitioning ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: selectedDate)
                    .animation(.easeInOut(duration: 0.3), value: todaySteps)
                    .animation(.easeInOut(duration: 0.3), value: selectedDateSteps)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
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
            fetchDailySteps(for: Date()) { steps in
                todaySteps = Int(steps)
            }
            prefetchMonthData()
        }
        .onChange(of: currentDate) { _ in
            prefetchMonthData()
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
        if calendar.isDateInToday(date) {
            return todaySteps >= viewModel.dailyGoal
        } else {
            // For past days, check the cache for actual step data
            if let cachedSteps = stepCountCache[calendar.startOfDay(for: date)] {
                return cachedSteps >= viewModel.dailyGoal
            }
            return false // Don't show fire if we don't have step data
        }
    }
    
    private func getStepCount(for date: Date) -> Int {
        // In a real app, this would fetch from HealthKit
        // For now, we'll use a placeholder value
        return 0
    }
    
    // Updated HealthKit query to fetch only the selected day's steps
    private func fetchDailySteps(for date: Date, completion: @escaping (Double) -> Void) {
        // Check if we already have cached data
        if let cachedSteps = stepCountCache[date] {
            completion(Double(cachedSteps))
            return
        }

        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            completion(0)
            return
        }
        
        // Get the step count type
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("Step count type is not available")
            completion(0)
            return
        }
        
        // Create the day range with proper boundaries
        let calendar = Calendar.current
        guard
            let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date),
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)
        else {
            print("Could not create date boundaries")
            completion(0)
            return
        }
        
        // Create a predicate that only includes samples from the selected day
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        // Create the statistics query
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            if let error = error {
                print("Error fetching step data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            guard let stats = result,
                  let quantity = stats.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(0)
                }
                return
            }
            
            // Get the step count as a double
            let stepCount = quantity.doubleValue(for: HKUnit.count())
            
            // Cache the result
            DispatchQueue.main.async {
                stepCountCache[date] = Int(stepCount)
                completion(stepCount)
            }
        }
        
        // Execute the query
        healthManager.healthStore.execute(query)
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
    
    // Add new prefetch function
    private func prefetchMonthData() {
        guard !isFetchingData else { return }
        isFetchingData = true
        
        // Get the date range for the current month
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
            isFetchingData = false
            return
        }
        
        // Create a predicate for the entire month
        let predicate = HKQuery.predicateForSamples(
            withStart: monthInterval.start,
            end: monthInterval.end,
            options: .strictStartDate
        )
        
        // Get the step count type
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            isFetchingData = false
            return
        }
        
        // Create a collection query for the month
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: monthInterval.start,
            intervalComponents: DateComponents(day: 1)
        )
        
        query.initialResultsHandler = { query, results, error in
            if let error = error {
                print("Error fetching month data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    isFetchingData = false
                }
                return
            }
            
            guard let statsCollection = results else {
                DispatchQueue.main.async {
                    isFetchingData = false
                }
                return
            }
            
            // Process each day's statistics
            statsCollection.enumerateStatistics(from: monthInterval.start, to: monthInterval.end) { statistics, _ in
                if let quantity = statistics.sumQuantity() {
                    let steps = Int(quantity.doubleValue(for: HKUnit.count()))
                    let date = statistics.startDate
                    
                    DispatchQueue.main.async {
                        stepCountCache[date] = steps
                    }
                }
            }
            
            DispatchQueue.main.async {
                isFetchingData = false
            }
        }
        
        // Execute the query
        healthManager.healthStore.execute(query)
    }
    
    private func getDailyKey(for date: Date) -> String {
        return DateFormatterManager.shared.dailyKeyFormatter.string(from: date)
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
            
            // Status icon - only show fire if we have actual step data
            if isGoalMet && stepCount > 0 {
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
