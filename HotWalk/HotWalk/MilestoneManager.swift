import Foundation
import SwiftUI

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