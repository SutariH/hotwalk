import SwiftUI

enum MilestoneType: String, CaseIterable {
    case threeDayStreak = "3-Day Streak"
    case fiveDayStreak = "5-Day Streak"
    case sevenDayStreak = "7-Day Streak"
    case tenDayStreak = "10-Day Streak"
    case halfGoal = "Half Goal"
    case fullGoal = "Full Goal"
    case doubleGoal = "Double Goal"
    
    var iconName: String {
        switch self {
        case .threeDayStreak: return "flame.fill"
        case .fiveDayStreak: return "flame.fill"
        case .sevenDayStreak: return "flame.fill"
        case .tenDayStreak: return "flame.fill"
        case .halfGoal: return "chart.bar.fill"
        case .fullGoal: return "trophy.fill"
        case .doubleGoal: return "star.fill"
        }
    }
    
    var title: String {
        switch self {
        case .threeDayStreak: return "3-Day Streak! 🔥"
        case .fiveDayStreak: return "5-Day Streak! 🔥"
        case .sevenDayStreak: return "7-Day Streak! 🔥"
        case .tenDayStreak: return "10-Day Streak! 🔥"
        case .halfGoal: return "Halfway There! 🎯"
        case .fullGoal: return "Goal Achieved! 🏆"
        case .doubleGoal: return "Double Goal! ⭐️"
        }
    }
    
    var description: String {
        switch self {
        case .threeDayStreak: return "You've walked for 3 days straight! Keep that hot girl energy going! 💃"
        case .fiveDayStreak: return "5 days of consistent walking! You're unstoppable! ✨"
        case .sevenDayStreak: return "A full week of walking! You're officially a walking queen! 👑"
        case .tenDayStreak: return "10 days of dedication! You're a walking legend! 🌟"
        case .halfGoal: return "You've reached 50% of your daily goal! Keep pushing! 💪"
        case .fullGoal: return "You've crushed your daily goal! Hot girl walk complete! 🎉"
        case .doubleGoal: return "You've doubled your goal! You're absolutely killing it! ��"
        }
    }
} 