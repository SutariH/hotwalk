import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HotWalkViewModel()
    @State private var currentDate = Date()
    @State private var selectedDate: Date? = nil
    @State private var showingDateInfo = false
    
    private let calendar = Calendar.current
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // Month subheadings dictionary with shorter, one-line versions
    private let monthSubheadings: [Int: String] = [
        1: "New Year, Hot You 💥",
        2: "Hot Girl, Full Heart 💘",
        3: "March & Slay 💃",
        4: "Bloom Mode: ON 🌸",
        5: "Main Char May ☀️",
        6: "Hot Girl Summer 🔥",
        7: "Sun's Out, Slay's Out 😎",
        8: "Peak Hotness 📈👣",
        9: "Boss Mode: Slaytember 💼",
        10: "Spooky. Sexy. Stepping. 🧙‍♀️",
        11: "Thankful & Thriving ✨🦃",
        12: "Sleigh the Month 🎄💅"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Month navigation
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Month title with subheading
                    VStack(spacing: 4) {
                        Text(getMonthSubheading())
                            .font(.title3.bold())
                            .foregroundColor(.purple)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                        
                        Text(monthYearString(from: currentDate))
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                // Streak and Pass Count Display
                HStack {
                    Text(viewModel.streakText)
                        .font(.title3)
                        .foregroundColor(.purple)
                    
                    Text("·")
                        .font(.title3)
                        .foregroundColor(.purple)
                    
                    Text("💌 \(HotGirlPassManager.shared.currentPassCount) Hot Girl Passes")
                        .font(.title3)
                        .foregroundColor(.purple)
                }
                .padding(.top, 5)
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isGoalMet: isGoalMet(for: date),
                                wasPassUsed: HotGirlPassManager.shared.wasPassUsed(on: date)
                            )
                            .onTapGesture {
                                selectedDate = date
                                showingDateInfo = true
                            }
                        } else {
                            Color.clear
                                .aspectRatio(1, contentMode: .fill)
                        }
                    }
                }
                .padding(.horizontal)
                
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
                                .font(.caption)
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
                                .font(.caption)
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
                                .font(.caption)
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
                        .fill(Color.white.opacity(0.7))
                        .shadow(radius: 3)
                )
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Calendar Legend: Goal met, Pass used, and Missed day indicators")
                
                Spacer()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.purple.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .navigationTitle("Hot Walk Calendar")
        .sheet(isPresented: $showingDateInfo) {
            if let date = selectedDate {
                DateInfoView(date: date, isGoalMet: isGoalMet(for: date), wasPassUsed: HotGirlPassManager.shared.wasPassUsed(on: date))
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
        let dateString = dateFormatter.string(from: date)
        return UserDefaults.standard.bool(forKey: "goal_completed_\(dateString)")
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
            } else if wasPassUsed {
                Text("💌")
                    .font(.system(size: 14))
                    .offset(x: 8, y: -8)
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
            return Color.purple
        } else if wasPassUsed {
            return Color.pink
        }
        return Color.primary
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
                    .foregroundColor(.purple)
                    .padding(.top)
                
                if isGoalMet {
                    VStack(spacing: 10) {
                        Text("🔥 Goal Achieved!")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        Text("You crushed your step goal this day!")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.purple)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.purple.opacity(0.1))
                    )
                } else if wasPassUsed {
                    VStack(spacing: 10) {
                        Text("💌 Hot Girl Pass Used")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                        
                        Text("You used a pass to preserve your streak!")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.pink)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.pink.opacity(0.1))
                    )
                } else {
                    VStack(spacing: 10) {
                        Text("No Goal Met")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        Text("You didn't meet your step goal this day.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Day Details")
            .navigationBarItems(trailing: Button("Done") {
                // Dismiss the sheet
            })
        }
    }
}

#Preview {
    NavigationView {
        CalendarView()
    }
} 