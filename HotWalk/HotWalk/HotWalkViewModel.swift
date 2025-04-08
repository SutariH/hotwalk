import Foundation
import SwiftUI

class HotWalkViewModel: ObservableObject {
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
    
    init() {
        self.dailyGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
        if self.dailyGoal == 0 {
            self.dailyGoal = 10000 // Default goal
        }
        self.streakText = StreakManager.shared.getStreakText()
        self.currentMessage = MotivationalMessageManager.shared.getMessage(for: 0.0)
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
        let previousStreak = StreakManager.shared.currentStreak
        
        // Try to use Hot Girl Pass if we're going to break the streak
        if progress < 1.0 && previousStreak > 0 {
            if HotGirlPassManager.shared.usePass() {
                DispatchQueue.main.async {
                    self.hotGirlPassMessage = "You missed your goal, but your Hot Girl Pass saved your streak 💌"
                }
                // Don't update streak if we used a pass
                return
            }
        }
        
        StreakManager.shared.updateStreak(progress: progress)
        DispatchQueue.main.async {
            // Only show the streak text without the pass count
            self.streakText = StreakManager.shared.getStreakText()
        }
    }
    
    // MARK: - Goal Completion Storage
    
    private func storeGoalCompletion(for date: Date, progress: Double) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let completed = progress >= 1.0
        UserDefaults.standard.set(completed, forKey: "goal_completed_\(dateString)")
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
} 