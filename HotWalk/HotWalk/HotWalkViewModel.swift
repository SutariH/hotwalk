import Foundation
import SwiftUI

class HotGirlStepsViewModel: ObservableObject {
    @Published var dailyGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
        }
    }
    
    @Published var steps: Int = 0
    @Published var streakText: String = ""
    @Published var currentMessage: String = ""
    @Published var hotGirlPassMessage: String = ""
    
    private var lastProgress: Double = 0.0
    private let progressThreshold: Double = 0.01 // Update message when progress changes by 1%
    private let calendar = Calendar.current
    
    init() {
        self.dailyGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
        if self.dailyGoal == 0 {
            self.dailyGoal = 5000 // Default goal changed from 10000 to 5000
        }
        self.streakText = StreakManager.shared.getStreakText()
        self.currentMessage = MotivationalMessageManager.shared.getMessage(for: 0.0)
        
        // Check for pass usage after midnight
        checkMidnightPassUsage()
    }
    
    private func checkMidnightPassUsage() {
        // Get yesterday's date
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            print("⚠️ Could not get yesterday's date in checkMidnightPassUsage")
            return
        }
        
        // Get yesterday's steps from storage
        let yesterdaySteps = getStoredSteps(for: yesterday)
        
        // Only proceed if we have valid step data
        guard yesterdaySteps > 0 else {
            print("⚠️ No step data available for yesterday")
            return
        }
        
        // Check for multiple missed days
        let lastSuccessDate = StreakManager.shared.lastSuccessDate
        if HotGirlPassManager.shared.checkAndApplyPassesForMissedDays(since: lastSuccessDate) {
            DispatchQueue.main.async {
                self.hotGirlPassMessage = "Your Hot Girl Pass saved your streak! 💌"
            }
        }
    }
    
    private func getStoredSteps(for date: Date) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return UserDefaults.standard.integer(forKey: "steps_\(dateString)")
    }
    
    func getMotivationalMessage(progress: Double) -> String {
        // Only update message if progress has changed significantly
        if abs(progress - lastProgress) >= progressThreshold {
            lastProgress = progress
            DispatchQueue.main.async {
                self.currentMessage = MotivationalMessageManager.shared.getMessage(for: progress)
            }
        }
        return currentMessage
    }
    
    func calculateProgress(steps: Int) -> Double {
        let progress = Double(steps) / Double(dailyGoal)
        
        // Check for Hot Girl Pass earning
        if HotGirlPassManager.shared.tryEarnPass(steps: steps, goal: dailyGoal) {
            DispatchQueue.main.async {
                self.hotGirlPassMessage = "You overachiever! +1 Hot Girl Pass unlocked 💅"
            }
        }
        
        // Update streak based on progress
        updateStreak(progress: progress)
        
        // Update message based on current progress
        DispatchQueue.main.async {
            self.currentMessage = self.getMotivationalMessage(progress: progress)
        }
        
        // Store goal completion status for today
        storeGoalCompletion(for: Date(), progress: progress)
        
        return progress
    }
    
    private func updateStreak(progress: Double) {
        StreakManager.shared.updateStreak(progress: progress)
        DispatchQueue.main.async {
            self.streakText = StreakManager.shared.getStreakText()
        }
    }
    
    // MARK: - Goal Completion Storage
    
    private func storeGoalCompletion(for date: Date, progress: Double) {
        let dateString = getDailyKey(for: date)
        let completed = progress >= 1.0
        
        UserDefaults.standard.set(completed, forKey: "goal_completed_\(dateString)")
        UserDefaults.standard.set(steps, forKey: "steps_\(dateString)")
        UserDefaults.standard.synchronize()
    }
    
    func wasGoalCompleted(for date: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        return UserDefaults.standard.bool(forKey: "goal_completed_\(dateString)")
    }
    
    func getCurrentStreak() -> Int {
        return StreakManager.shared.currentStreak
    }
    
    private func getDailyKey(for date: Date) -> String {
        return DateFormatterManager.shared.dailyKeyFormatter.string(from: date)
    }
} 