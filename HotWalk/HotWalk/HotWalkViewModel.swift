import Foundation
import SwiftUI

class HotWalkViewModel: ObservableObject {
    @Published var dailyGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
        }
    }
    
    @Published var streakText: String = ""
    @Published var currentMessage: String = ""
    
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