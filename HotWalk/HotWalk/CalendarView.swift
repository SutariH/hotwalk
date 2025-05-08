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

enum ViewType {
    case day
    case week
    case month
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
    @State private var distanceCache: [Date: Double] = [:]
    @State private var activeTimeCache: [Date: TimeInterval] = [:]
    @State private var isFetchingData: Bool = false
    @State private var isInitialLoadComplete: Bool = false
    @State private var visibleDays: Set<Date> = []
    @State private var selectedViewType: ViewType = .day
    @State private var selectedMonthDate: Date = Calendar.current.startOfMonth(for: Date())
    
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
                    // View Type Selector
                    Picker("View Type", selection: $selectedViewType) {
                        Text("Day").tag(ViewType.day)
                        Text("Week").tag(ViewType.week)
                        Text("Month").tag(ViewType.month)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .accentColor(Color(red: 44/255, green: 8/255, blue: 52/255)) // Dark purple for selected segment
                    .foregroundColor(.white) // White text for unselected segments
                    
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
                                let isInSelectedMonth = selectedViewType == .month && calendar.isDate(date, equalTo: selectedMonthDate, toGranularity: .month)
                                DayCell(
                                    date: date,
                                    isGoalMet: isGoalMet(for: date),
                                    wasPassUsed: HotGirlPassManager.shared.wasPassUsed(on: date),
                                    stepCount: getStepCount(for: date),
                                    isSelected: selectedDate != nil && calendar.isDate(selectedDate!, inSameDayAs: date),
                                    isInSelectedWeek: selectedViewType == .week && isDateInSelectedWeek(date),
                                    isInSelectedMonth: isInSelectedMonth
                                )
                                .onAppear {
                                    if isInitialLoadComplete {
                                        loadDataForVisibleDays()
                                    }
                                }
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isTransitioning = true
                                        selectedDate = date
                                        fetchDailyData(for: date)
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
                    
                    // Stats View based on selected type
                    switch selectedViewType {
                    case .day:
                        DayStatsView(
                            date: selectedDate ?? Date(),
                            steps: selectedDate == nil ? todaySteps : selectedDateSteps,
                            distance: selectedDate == nil ? todayDistance : selectedDateDistance,
                            activeTime: selectedDate == nil ? todayActiveTime : selectedDateActiveTime,
                            isTransitioning: isTransitioning
                        )
                    case .week:
                        WeekStatsView(
                            startDate: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate ?? Date())) ?? Date(),
                            stepCountCache: stepCountCache,
                            distanceCache: distanceCache,
                            activeTimeCache: activeTimeCache
                        )
                    case .month:
                        MonthStatsView(
                            selectedMonthDate: selectedMonthDate,
                            stepCountCache: stepCountCache,
                            distanceCache: distanceCache,
                            activeTimeCache: activeTimeCache,
                            onSelectMonth: { date in
                                selectedMonthDate = date
                                currentDate = date
                            }
                        )
                    }
                    
                    // Hot Girl Passes Explanation
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                            Text("Hot Girl Passes")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text("You have \(HotGirlPassManager.shared.currentPassCount) Hot Girl Passes")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Hot Girl Passes are your secret weapon for keeping that streak alive when life’s being extra. They kick in automatically if you miss your step goal — and guess what? You can earn more by totally crushing it with 150% of your goal!")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.vertical)
            }
            .refreshable {
                let today = Date()
                currentDate = today
                selectedDate = today
                selectedMonthDate = calendar.startOfMonth(for: today)
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
            if selectedViewType == .week {
                fetchAndCacheWeekDistanceAndTime()
            }
        }
        .onChange(of: selectedViewType) { newValue in
            if newValue == .week {
                fetchAndCacheWeekDistanceAndTime()
            }
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
    
    private func fetchDailyData(for date: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        
        // Fetch steps
        if let cachedSteps = stepCountCache[startOfDay] {
            selectedDateSteps = cachedSteps
        } else {
            healthManager.fetchStepsForDate(date) { steps in
                self.selectedDateSteps = steps
                self.stepCountCache[startOfDay] = steps
            }
        }
        
        // Fetch distance
        if let cachedDistance = distanceCache[startOfDay] {
            selectedDateDistance = cachedDistance
        } else {
            healthManager.fetchDistanceForDate(date) { distance in
                self.selectedDateDistance = distance
                self.distanceCache[startOfDay] = distance
            }
        }
        
        // Fetch active time
        if let cachedTime = activeTimeCache[startOfDay] {
            selectedDateActiveTime = cachedTime
        } else {
            healthManager.fetchActiveTimeForDate(date) { activeTime in
                self.selectedDateActiveTime = activeTime
                self.activeTimeCache[startOfDay] = activeTime
            }
        }
        
        selectedDateStatus = getStatus(for: date)
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
    
    // Helper to check if a date is in the selected week
    private func isDateInSelectedWeek(_ date: Date) -> Bool {
        guard selectedViewType == .week else { return false }
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate ?? Date())) ?? Date()
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return (date >= calendar.startOfDay(for: weekStart) && date <= calendar.startOfDay(for: weekEnd))
    }
    
    // Helper to fetch and cache distance and time for all days in the selected week
    private func fetchAndCacheWeekDistanceAndTime() {
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate ?? Date())) ?? Date()
        for offset in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: offset, to: weekStart) {
                let startOfDay = calendar.startOfDay(for: day)
                if distanceCache[startOfDay] == nil {
                    healthManager.fetchDistanceForDate(day) { distance in
                        DispatchQueue.main.async {
                            distanceCache[startOfDay] = distance
                        }
                    }
                }
                if activeTimeCache[startOfDay] == nil {
                    healthManager.fetchActiveTimeForDate(day) { activeTime in
                        DispatchQueue.main.async {
                            activeTimeCache[startOfDay] = activeTime
                        }
                    }
                }
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isGoalMet: Bool
    let wasPassUsed: Bool
    let stepCount: Int
    let isSelected: Bool
    let isInSelectedWeek: Bool
    let isInSelectedMonth: Bool
    
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
                .scaleEffect(isSelected ? 1.18 : 1.0)
                .overlay(
                    // White border and glow for selected day (in day view), all days in selected week (in week view), or all days in selected month (in month view)
                    Circle()
                        .stroke((isSelected && !isInSelectedWeek && !isInSelectedMonth) || isInSelectedWeek || isInSelectedMonth ? Color.white : Color.clear, lineWidth: ((isSelected && !isInSelectedWeek && !isInSelectedMonth) || isInSelectedWeek || isInSelectedMonth) ? 4 : 0)
                        .shadow(color: ((isSelected && !isInSelectedWeek && !isInSelectedMonth) || isInSelectedWeek || isInSelectedMonth) ? Color.purple.opacity(0.7) : Color.clear, radius: ((isSelected && !isInSelectedWeek && !isInSelectedMonth) || isInSelectedWeek || isInSelectedMonth) ? 8 : 0)
                )
            
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

// Add new view for day stats
struct DayStatsView: View {
    let date: Date
    let steps: Int
    let distance: Double
    let activeTime: TimeInterval
    let isTransitioning: Bool
    
    private var useMetricSystem: Bool {
        UserDefaults.standard.bool(forKey: "useMetricSystem")
    }
    
    private var distanceUnit: String {
        useMetricSystem ? "km" : "mi"
    }
    
    private func convertDistance(_ kilometers: Double) -> Double {
        if !useMetricSystem {
            return kilometers * 0.621371
        }
        return kilometers
    }
    
    private func formatDistance(_ kilometers: Double) -> String {
        let convertedDistance = convertDistance(kilometers)
        return String(format: "%.1f %@", convertedDistance, distanceUnit)
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
    
    var body: some View {
        VStack(spacing: 15) {
            // Date header
            Text(formatDate(date))
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.top, 5)
            
            // Stats cards
            VStack(spacing: 12) {
                StatCard(title: "Steps", value: "\(steps)", icon: "figure.walk")
                StatCard(title: "Distance", value: formatDistance(distance), icon: "map")
                StatCard(title: "Active Time", value: formatTime(activeTime), icon: "clock")
            }
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(15)
        }
        .padding(.horizontal)
        .opacity(isTransitioning ? 0 : 1)
        .animation(.easeInOut(duration: 0.3), value: isTransitioning)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// Add new view for week stats
struct WeekStatsView: View {
    let startDate: Date
    let stepCountCache: [Date: Int]
    let distanceCache: [Date: Double]
    let activeTimeCache: [Date: TimeInterval]
    
    private let calendar = Calendar.current
    
    private var weekDates: [Date] {
        (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startDate)
        }
    }
    
    private var totalSteps: Int {
        weekDates.reduce(0) { total, date in
            total + (stepCountCache[calendar.startOfDay(for: date)] ?? 0)
        }
    }
    
    private var totalDistance: Double {
        weekDates.reduce(0.0) { total, date in
            total + (distanceCache[calendar.startOfDay(for: date)] ?? 0)
        }
    }
    
    private var totalActiveTime: TimeInterval {
        weekDates.reduce(0.0) { total, date in
            total + (activeTimeCache[calendar.startOfDay(for: date)] ?? 0)
        }
    }
    
    private var useMetricSystem: Bool {
        UserDefaults.standard.bool(forKey: "useMetricSystem")
    }
    
    private var distanceUnit: String {
        useMetricSystem ? "km" : "mi"
    }
    
    private func convertDistance(_ kilometers: Double) -> Double {
        if !useMetricSystem {
            return kilometers * 0.621371
        }
        return kilometers
    }
    
    private func formatDistance(_ kilometers: Double) -> String {
        let convertedDistance = convertDistance(kilometers)
        return String(format: "%.1f %@", convertedDistance, distanceUnit)
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
    
    // For bar graph
    private var maxSteps: Int {
        (weekDates.map { stepCountCache[calendar.startOfDay(for: $0)] ?? 0 }.max() ?? 1)
    }
    
    // Highlight the selected week
    private var isSelectedWeek: Bool {
        // Always true for now, as this is the week being viewed
        true
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Large total steps
            Text("\(totalSteps)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 8)
            // Subtitle
            Text(weekSubtitle())
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            // Bar graph for each day
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weekDates, id: \.self) { date in
                    let steps = stepCountCache[calendar.startOfDay(for: date)] ?? 0
                    VStack {
                        Text("\(steps)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.7)]), startPoint: .bottom, endPoint: .top))
                            .frame(width: 24, height: barHeight(for: steps))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.clear, lineWidth: 0)
                            )
                        Text(shortWeekday(for: date))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(height: 100)
            // Summary row
            HStack(spacing: 32) {
                VStack {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.purple)
                    Text(formatDistance(totalDistance))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                VStack {
                    Image(systemName: "clock")
                        .foregroundColor(.purple)
                    Text(formatTime(totalActiveTime))
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    private func weekSubtitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        let start = formatter.string(from: weekDates.first ?? Date())
        let end = formatter.string(from: weekDates.last ?? Date())
        return "\(start) – \(end)"
    }
    
    private func shortWeekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func barHeight(for steps: Int) -> CGFloat {
        let minHeight: CGFloat = 16
        let maxHeight: CGFloat = 80
        guard maxSteps > 0 else { return minHeight }
        let ratio = CGFloat(steps) / CGFloat(maxSteps)
        return max(minHeight, ratio * maxHeight)
    }
}

// Add new view for month stats
struct MonthStatsView: View {
    let selectedMonthDate: Date
    let stepCountCache: [Date: Int]
    let distanceCache: [Date: Double]
    let activeTimeCache: [Date: TimeInterval]
    let onSelectMonth: (Date) -> Void
    
    private let calendar = Calendar.current
    
    // Get the last 6 months including the selected month
    private var lastSixMonths: [Date] {
        (0..<6).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: calendar.startOfMonth(for: selectedMonthDate))
        }.reversed()
    }
    
    // Get totals for a given month
    private func totals(for month: Date) -> (steps: Int, distance: Double, activeTime: TimeInterval) {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return (0, 0, 0) }
        let days = calendar.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
        let steps = days.reduce(0) { $0 + (stepCountCache[calendar.startOfDay(for: $1)] ?? 0) }
        let distance = days.reduce(0.0) { $0 + (distanceCache[calendar.startOfDay(for: $1)] ?? 0) }
        let activeTime = days.reduce(0.0) { $0 + (activeTimeCache[calendar.startOfDay(for: $1)] ?? 0) }
        return (steps, distance, activeTime)
    }
    
    private var selectedTotals: (steps: Int, distance: Double, activeTime: TimeInterval) {
        totals(for: selectedMonthDate)
    }
    
    private var useMetricSystem: Bool {
        UserDefaults.standard.bool(forKey: "useMetricSystem")
    }
    
    private var distanceUnit: String {
        useMetricSystem ? "km" : "mi"
    }
    
    private func convertDistance(_ kilometers: Double) -> Double {
        if !useMetricSystem {
            return kilometers * 0.621371
        }
        return kilometers
    }
    
    private func formatDistance(_ kilometers: Double) -> String {
        let convertedDistance = convertDistance(kilometers)
        return String(format: "%.1f %@", convertedDistance, distanceUnit)
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
    
    // For bar chart
    private var maxSteps: Int {
        lastSixMonths.map { totals(for: $0).steps }.max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Large total steps
            Text("\(selectedTotals.steps)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 8)
            // Subtitle
            Text(monthSubtitle(for: selectedMonthDate))
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            // Bar chart for last 6 months
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(lastSixMonths, id: \.self) { month in
                    let totals = totals(for: month)
                    VStack {
                        Text("\(totals.steps)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.7)]), startPoint: .bottom, endPoint: .top))
                            .frame(width: 24, height: barHeight(for: totals.steps))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(calendar.isDate(month, equalTo: selectedMonthDate, toGranularity: .month) ? Color.white : Color.clear, lineWidth: calendar.isDate(month, equalTo: selectedMonthDate, toGranularity: .month) ? 4 : 0)
                                    .shadow(color: calendar.isDate(month, equalTo: selectedMonthDate, toGranularity: .month) ? Color.purple.opacity(0.7) : Color.clear, radius: calendar.isDate(month, equalTo: selectedMonthDate, toGranularity: .month) ? 8 : 0)
                            )
                            .onTapGesture {
                                onSelectMonth(month)
                            }
                        Text(shortMonth(for: month))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(height: 100)
            // Summary row
            HStack(spacing: 32) {
                VStack {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.purple)
                    Text(formatDistance(selectedTotals.distance))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                VStack {
                    Image(systemName: "clock")
                        .foregroundColor(.purple)
                    Text(formatTime(selectedTotals.activeTime))
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    private func monthSubtitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func shortMonth(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func barHeight(for steps: Int) -> CGFloat {
        let minHeight: CGFloat = 16
        let maxHeight: CGFloat = 80
        guard maxSteps > 0 else { return minHeight }
        let ratio = CGFloat(steps) / CGFloat(maxSteps)
        return max(minHeight, ratio * maxHeight)
    }
}

// Simple SwiftUI line graph for steps
struct LineGraph: View {
    let data: [Int]
    let maxValue: Int
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let count = data.count
            let points: [CGPoint] = data.enumerated().map { (i, value) in
                let x = CGFloat(i) / CGFloat(max(count - 1, 1)) * width
                let y = height - (CGFloat(value) / CGFloat(maxValue)) * (height - 16)
                return CGPoint(x: x, y: y)
            }
            ZStack {
                // Line
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.7)]), startPoint: .bottom, endPoint: .top), lineWidth: 3)
                // Dots
                ForEach(points.indices, id: \.self) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .position(points[i])
                }
            }
        }
    }
}

// Add helper views for breakdowns
struct DailyBreakdownRow: View {
    let date: Date
    let steps: Int
    let distance: Double
    let activeTime: TimeInterval
    
    private let calendar = Calendar.current
    
    private var useMetricSystem: Bool {
        UserDefaults.standard.bool(forKey: "useMetricSystem")
    }
    
    private var distanceUnit: String {
        useMetricSystem ? "km" : "mi"
    }
    
    private func convertDistance(_ kilometers: Double) -> Double {
        if !useMetricSystem {
            return kilometers * 0.621371
        }
        return kilometers
    }
    
    private func formatDistance(_ kilometers: Double) -> String {
        let convertedDistance = convertDistance(kilometers)
        return String(format: "%.1f %@", convertedDistance, distanceUnit)
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
    
    var body: some View {
        HStack {
            Text(formatDate(date))
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(steps) steps")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(formatDistance(distance))
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(formatTime(activeTime))
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}

struct WeeklyBreakdownRow: View {
    let startDate: Date
    let stepCountCache: [Date: Int]
    let distanceCache: [Date: Double]
    let activeTimeCache: [Date: TimeInterval]
    
    private let calendar = Calendar.current
    
    private var weekDates: [Date] {
        (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startDate)
        }
    }
    
    private var totalSteps: Int {
        weekDates.reduce(0) { total, date in
            total + (stepCountCache[calendar.startOfDay(for: date)] ?? 0)
        }
    }
    
    private var totalDistance: Double {
        weekDates.reduce(0.0) { total, date in
            total + (distanceCache[calendar.startOfDay(for: date)] ?? 0)
        }
    }
    
    private var totalActiveTime: TimeInterval {
        weekDates.reduce(0.0) { total, date in
            total + (activeTimeCache[calendar.startOfDay(for: date)] ?? 0)
        }
    }
    
    private var useMetricSystem: Bool {
        UserDefaults.standard.bool(forKey: "useMetricSystem")
    }
    
    private var distanceUnit: String {
        useMetricSystem ? "km" : "mi"
    }
    
    private func convertDistance(_ kilometers: Double) -> Double {
        if !useMetricSystem {
            return kilometers * 0.621371
        }
        return kilometers
    }
    
    private func formatDistance(_ kilometers: Double) -> String {
        let convertedDistance = convertDistance(kilometers)
        return String(format: "%.1f %@", convertedDistance, distanceUnit)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Week of \(formatDate(startDate))")
                .font(.subheadline)
                .foregroundColor(.white)
            
            HStack {
                Text("\(totalSteps) steps")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(formatDistance(totalDistance))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(formatTime(totalActiveTime))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// Add Calendar extension for date generation
extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date <= interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}

// Calendar extension for startOfMonth
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        return self.date(from: self.dateComponents([.year, .month], from: date)) ?? date
    }
}

#Preview {
    NavigationView {
        CalendarView()
    }
} 
