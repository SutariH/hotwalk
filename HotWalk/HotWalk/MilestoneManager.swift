import Foundation
import SwiftUI

// Define milestone types
enum MilestoneType: String, CaseIterable {
    case threeDayStreak = "3-Day Streak"
    case sevenDayStreak = "7-Day Streak"
    case oneHundredTwentyFivePercent = "125% Goal"
    case oneHundredFiftyPercent = "150% Goal"
    case twoHundredPercent = "200% Goal"
    
    var message: String {
        switch self {
        case .threeDayStreak:
            return "Okayyy consistency queen 👑 You've walked hot 3 days in a row."
        case .sevenDayStreak:
            return "You just earned 7 days of main character energy. Keep slaying."
        case .oneHundredTwentyFivePercent:
            return "You didn't walk. You WERKED. 125% hotness achieved."
        case .oneHundredFiftyPercent:
            return "The sidewalk is jealous. 150% slay complete."
        case .twoHundredPercent:
            return "NASA called. You walked straight into orbit 💫"
        }
    }
    
    var icon: String {
        switch self {
        case .threeDayStreak:
            return "🔥"
        case .sevenDayStreak:
            return "👑"
        case .oneHundredTwentyFivePercent:
            return "✨"
        case .oneHundredFiftyPercent:
            return "🔥"
        case .twoHundredPercent:
            return "🚀"
        }
    }
}

class MilestoneManager: ObservableObject {
    static let shared = MilestoneManager()
    
    @Published var currentMilestone: MilestoneType?
    @Published var showMilestoneCard = false
    
    private let userDefaults = UserDefaults.standard
    private let shownMilestonesKey = "shownMilestones"
    
    private init() {}
    
    private func getDailyKey(for date: Date) -> String {
        return DateFormatterManager.shared.dailyKeyFormatter.string(from: date)
    }
    
    // Check if a milestone has been shown today
    private func hasShownMilestoneToday(_ milestone: MilestoneType) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        
        let shownMilestones = userDefaults.dictionary(forKey: shownMilestonesKey) as? [String: String] ?? [:]
        return shownMilestones[milestone.rawValue] == todayString
    }
    
    // Mark a milestone as shown today
    private func markMilestoneAsShown(_ milestone: MilestoneType) {
        let today = Calendar.current.startOfDay(for: Date())
        let todayString = getDailyKey(for: today)
        
        var shownMilestones = UserDefaults.standard.dictionary(forKey: shownMilestonesKey) as? [String: String] ?? [:]
        shownMilestones[milestone.rawValue] = todayString
        UserDefaults.standard.set(shownMilestones, forKey: shownMilestonesKey)
        UserDefaults.standard.synchronize()
    }
    
    // Check for milestones based on streak and progress
    func checkForMilestones(streak: Int, progress: Double) -> MilestoneType? {
        // Check streak milestones
        if streak == 3 && !hasShownMilestoneToday(.threeDayStreak) {
            markMilestoneAsShown(.threeDayStreak)
            return .threeDayStreak
        } else if streak == 7 && !hasShownMilestoneToday(.sevenDayStreak) {
            markMilestoneAsShown(.sevenDayStreak)
            return .sevenDayStreak
        }
        
        // Check progress milestones
        if progress >= 2.0 && !hasShownMilestoneToday(.twoHundredPercent) {
            markMilestoneAsShown(.twoHundredPercent)
            return .twoHundredPercent
        } else if progress >= 1.5 && !hasShownMilestoneToday(.oneHundredFiftyPercent) {
            markMilestoneAsShown(.oneHundredFiftyPercent)
            return .oneHundredFiftyPercent
        } else if progress >= 1.25 && !hasShownMilestoneToday(.oneHundredTwentyFivePercent) {
            markMilestoneAsShown(.oneHundredTwentyFivePercent)
            return .oneHundredTwentyFivePercent
        }
        
        return nil
    }
    
    // Show a milestone card
    private func showMilestone(_ milestone: MilestoneType) {
        DispatchQueue.main.async {
            self.currentMilestone = milestone
            self.showMilestoneCard = true
            self.markMilestoneAsShown(milestone)
        }
    }
    
    // Dismiss the milestone card
    func dismissMilestoneCard() {
        DispatchQueue.main.async {
            self.showMilestoneCard = false
        }
    }
} 