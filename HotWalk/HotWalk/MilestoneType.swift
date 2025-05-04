import SwiftUI

enum MilestoneType: String, CaseIterable {
    case threeDayStreak = "3-Day Streak"
    case fiveDayStreak = "5-Day Streak"
    case sevenDayStreak = "7-Day Streak"
    case tenDayStreak = "10-Day Streak"
    case oneHundredTwentyFivePercent = "125% Goal"
    case oneHundredFiftyPercent = "150% Goal"
    case twoHundredPercent = "200% Goal"
    
    var title: String {
        switch self {
        case .threeDayStreak: return "3-Day Streak! 🔥"
        case .fiveDayStreak: return "5-Day Streak! 🔥"
        case .sevenDayStreak: return "7-Day Streak! 🔥"
        case .tenDayStreak: return "10-Day Streak! 🔥"
        case .oneHundredTwentyFivePercent: return "125% Goal! 🎯"
        case .oneHundredFiftyPercent: return "150% Goal! 🏆"
        case .twoHundredPercent: return "200% Goal! ⭐️"
        }
    }
    
    var description: String {
        switch self {
        case .threeDayStreak: return "Okayyy consistency queen 👑 You've walked 3 days in a row."
        case .fiveDayStreak: return "5 days of consistent walking! You're unstoppable! ✨"
        case .sevenDayStreak: return "You just earned 7 days of main character energy. Keep slaying."
        case .tenDayStreak: return "10 days of dedication! You're a walking legend! 🌟"
        case .oneHundredTwentyFivePercent: return "You didn't walk. You WERKED. 125% hotness achieved."
        case .oneHundredFiftyPercent: return "The sidewalk is jealous. 150% slay complete."
        case .twoHundredPercent: return "NASA called. You walked straight into orbit 💫"
        }
    }
    
    var icon: String {
        switch self {
        case .threeDayStreak: return "🔥"
        case .fiveDayStreak: return "🔥"
        case .sevenDayStreak: return "👑"
        case .tenDayStreak: return "🌟"
        case .oneHundredTwentyFivePercent: return "✨"
        case .oneHundredFiftyPercent: return "🔥"
        case .twoHundredPercent: return "🚀"
        }
    }
} 
