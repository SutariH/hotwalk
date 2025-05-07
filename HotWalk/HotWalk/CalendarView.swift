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
    @StateObject private var viewModel = HotGirlStepsViewModel()
    @StateObject private var healthManager = HealthManager()
    @State private var currentDate = Date()
    @State private var selectedDate: Date? = nil
    @State private var selectedDateSteps: Int = 0
    @State private var selectedDateDistance: Double = 0
    @State private var selectedDateActiveTime: TimeInterval = 0
    @State private var selectedDateStatus: DayStatus = .none
    @State private var todaySteps: Int = 0
    @State private var todayDistance: Double = 0
    @State private var todayActiveTime: TimeInterval = 0
    @State private var isTransitioning: Bool = false
    @State private var stepCountCache: [Date: Int] = [:]
    @State private var isFetchingData: Bool = false
    @State private var isInitialLoadComplete: Bool = false
    @State private var visibleDays: Set<Date> = []
    
    private let calendar = Calendar.current
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // Add property to check user's unit preference
    private var useMetricSystem: Bool {
        UserDefaults.standard.bool(forKey: "useMetricSystem")
    }
    
    // Add property to get distance unit
    private var distanceUnit: String {
        useMetricSystem ? "km" : "mi"
    }
    
    // Add property to convert distance
    private func convertDistance(_ kilometers: Double) -> Double {
        if !useMetricSystem {
            return kilometers * 0.621371 // Convert km to miles
        }
        return kilometers
    }
    
    // Add property to format distance
    private func formatDistance(_ kilometers: Double) -> String {
        let convertedDistance = convertDistance(kilometers)
        return String(format: "%.1f %@", convertedDistance, distanceUnit)
    }
    
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
    
    private func loadInitialData() {
        // First, load today's data
        let today = Date()
        healthManager.fetchStepsForDate(today) { steps in
            self.todaySteps = steps
            self.stepCountCache[today] = steps
        }
        
        healthManager.fetchDistanceForDate(today) { distance in
            self.todayDistance = distance
        }
        
        healthManager.fetchActiveTimeForDate(today) { activeTime in
            self.todayActiveTime = activeTime
        }
        
        // Then start loading the current month's data in the background
        DispatchQueue.global(qos: .userInitiated).async {
            prefetchMonthData()
            DispatchQueue.main.async {
                isInitialLoadComplete = true
            }
        }
    }
    
    private func loadDataForVisibleDays() {
        let visibleDates = daysInMonth().compactMap { $0 }
        let newDates = Set(visibleDates).subtracting(visibleDays)
        
        guard !newDates.isEmpty else { return }
        
        isFetchingData = true
        visibleDays.formUnion(newDates)
        
        // Load data for newly visible days in batches
        let batchSize = 5
        for batch in stride(from: 0, to: newDates.count, by: batchSize) {
            let endIndex = min(batch + batchSize, newDates.count)
            let batchDates = Array(newDates)[batch..<endIndex]
            
            DispatchQueue.global(qos: .userInitiated).async {
                let group = DispatchGroup()
                
                for date in batchDates {
                    group.enter()
                    healthManager.fetchStepsForDate(date) { steps in
                        DispatchQueue.main.async {
                            self.stepCountCache[date] = steps
                        }
                        group.leave()
                    }
                }
                
                group.wait()
                
                DispatchQueue.main.async {
                    if batch + batchSize >= newDates.count {
                        isFetchingData = false
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 44/255, green: 8/255, blue: 52/255), // Dark purple
                    Color(red: 0.4, green: 0.2, blue: 0.4), // Medium purple
                    Color(hue: 0.83, saturation: 0.4, brightness: 0.8) // Darker purple
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
                                .onAppear {
                                    if isInitialLoadComplete {
                                        loadDataForVisibleDays()
                                    }
                                }
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isTransitioning = true
                                        
                                        if let selectedDate = selectedDate, calendar.isDate(selectedDate, inSameDayAs: date) {
                                            self.selectedDate = nil
                                            selectedDateStatus = .none
                                        } else {
                                            self.selectedDate = date
                                            fetchDailySteps(for: date) { steps in
                                                selectedDateSteps = steps
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
                        .background(Color.purple.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.purple.opacity(0.4), radius: 5, x: 0, y: 2)
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
                        .background(Color.pink.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.pink.opacity(0.4), radius: 5, x: 0, y: 2)
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
                        .background(Color.purple.opacity(0.25))
                        .cornerRadius(15)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(selectedDate == nil ? todaySteps : selectedDateSteps) steps out of \(viewModel.dailyGoal) goal")
                        
                        // Distance and Active Time
                        HStack(spacing: 20) {
                            // Distance
                            VStack(spacing: 8) {
                                Text("Distance")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(formatDistance(selectedDate == nil ? todayDistance : selectedDateDistance))
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.25))
                            .cornerRadius(15)
                            
                            // Active Time
                            VStack(spacing: 8) {
                                Text("Active Time")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(formatTime(selectedDate == nil ? todayActiveTime : selectedDateActiveTime))
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.25))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        
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
                                        (todaySteps >= viewModel.dailyGoal ? Color.purple.opacity(0.25) : Color.gray.opacity(0.25)) :
                                        (selectedDateSteps >= viewModel.dailyGoal ? Color.purple.opacity(0.25) : Color.gray.opacity(0.25))
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
                                    .fill(Color.white.opacity(0.15))
                            )
                            .shadow(color: Color.purple.opacity(0.4), radius: 5, x: 0, y: 0)
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
            leading: EmptyView()
        )
        .onAppear {
            loadInitialData()
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
    private func fetchDailySteps(for date: Date, completion: @escaping (Int) -> Void) {
        // Check if we already have the data cached
        let startOfDay = Calendar.current.startOfDay(for: date)
        if let cachedSteps = stepCountCache[startOfDay] {
            updateStepsForDate(startOfDay, steps: cachedSteps)
            completion(cachedSteps)
            return
        }
        
        // If not cached, fetch from HealthKit
        healthManager.fetchStepsForDate(date) { steps in
            self.updateStepsForDate(startOfDay, steps: steps)
            completion(steps)
        }
    }
    
    private func fetchDailyDistance(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let cachedDistance = healthManager.getDistanceForDate(startOfDay)
        if cachedDistance > 0 {
            updateDistanceForDate(startOfDay, distance: cachedDistance)
            return
        }
        
        healthManager.fetchDistanceForDate(date) { distance in
            self.updateDistanceForDate(startOfDay, distance: distance)
        }
    }
    
    private func fetchDailyActiveTime(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let cachedTime = healthManager.getActiveTimeForDate(startOfDay)
        if cachedTime > 0 {
            updateActiveTimeForDate(startOfDay, activeTime: cachedTime)
            return
        }
        
        healthManager.fetchActiveTimeForDate(date) { activeTime in
            self.updateActiveTimeForDate(startOfDay, activeTime: activeTime)
        }
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
        
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
            isFetchingData = false
            return
        }
        
        // Fetch data for each day in the month
        let group = DispatchGroup()
        
        for day in 0..<calendar.range(of: .day, in: .month, for: currentDate)!.count {
            guard let date = calendar.date(byAdding: .day, value: day, to: monthInterval.start) else { continue }
            
            group.enter()
            healthManager.fetchStepsForDate(date) { steps in
                DispatchQueue.main.async {
                    self.stepCountCache[date] = steps
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            isFetchingData = false
        }
    }
    
    private func getDailyKey(for date: Date) -> String {
        return DateFormatterManager.shared.dailyKeyFormatter.string(from: date)
    }
    
    private func getMonthIndex(_ date: Date) -> Int {
        if let index = calendar.dateComponents([.month], from: date).month {
            return index - 1
        }
        return 0
    }
    
    private func getWeekIndex(_ date: Date) -> Int {
        if let index = calendar.dateComponents([.weekOfMonth], from: date).weekOfMonth {
            return index - 1
        }
        return 0
    }
    
    private func getDayIndex(_ date: Date) -> Int {
        if let index = calendar.dateComponents([.weekday], from: date).weekday {
            return index - 1
        }
        return 0
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func updateStepsForDate(_ date: Date, steps: Int) {
        if calendar.isDateInToday(date) {
            todaySteps = steps
        }
        stepCountCache[date] = steps
    }
    
    private func updateDistanceForDate(_ date: Date, distance: Double) {
        if calendar.isDateInToday(date) {
            todayDistance = distance
        }
    }
    
    private func updateActiveTimeForDate(_ date: Date, activeTime: TimeInterval) {
        if calendar.isDateInToday(date) {
            todayActiveTime = activeTime
        }
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
            return Color.purple.opacity(0.35)
        } else if wasPassUsed {
            return Color.pink.opacity(0.35)
        }
        return Color.clear
    }
    
    private var borderColor: Color {
        if isGoalMet {
            return Color.purple.opacity(0.9)
        } else if wasPassUsed {
            return Color.pink.opacity(0.9)
        }
        return Color.gray.opacity(0.4)
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

#Preview {
    NavigationView {
        CalendarView()
    }
} 
